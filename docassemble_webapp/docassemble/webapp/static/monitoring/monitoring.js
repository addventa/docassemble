export async function launch_monitoring(api_key, callback) {
  async function get_projects(user_id) {
    let url = `/api/playground/project?key=${api_key}&user_id=${user_id}`;
    const res_projects = await fetch(url);
    return res_projects.ok ? res_projects.json() : [];
  }

  async function get_files_list(user_id, folder, project = "default") {
    let url = `/api/playground?key=${api_key}&user_id=${user_id}&folder=${folder}`;
    if (project !== "default") url += `&project=${project}`;
    const res_files_list = await fetch(url);
    return res_files_list.ok ? res_files_list.json() : [];
  }

  async function get_file(user_id, folder, filename, project = "default") {
    let url = `/api/playground?key=${api_key}&user_id=${user_id}&folder=${folder}&filename=${filename}`;
    if (project !== "default") url += `&project=${project}`;
    const res_file = await fetch(url);
    return res_file.ok ? res_file.blob() : null;
  }

  async function get_folder_files(user_id, folder, project = "default") {
    const promises = [];
    for (const file of await get_files_list(user_id, folder, project))
      promises.push({
        name: file,
        data: get_file(user_id, folder, file, project),
      });
    return promises;
  }

  async function get_project_folders(user_id, project = "default") {
    const promises = [];
    for (const folder of ["questions", "templates", "static"])
      promises.push({
        name: folder,
        files: get_folder_files(user_id, folder, project),
      });
    return promises;
  }

  async function get_playground_files(user_id) {
    const promises = [];
    promises.push({ name: "default", folders: get_project_folders(user_id) });

    const projects = await get_projects(user_id);
    for (const project of projects)
      promises.push({
        name: project,
        folders: get_project_folders(user_id, project),
      });
    return promises;
  }

  async function get_installed_projects() {
    const res_packages = await fetch(`/api/package?key=${api_key}`);
    if (!res_packages.ok) return []
    
    const packages = await res_packages.json();
    return packages
      .filter((x) => x.type === "zip")
      .map((x) => x.name.replace("docassemble.", ""));
  }

  async function compute_usage_from_logs() {
    callback("Retrieving log files...");
    const log_files = [];
    const res = await fetch("/logfile/access.log");
    const log = await res.text();
    log_files.push(log);

    for (let i = 1; i < 8; i++) {
      const res = await fetch(`/logfile/access.log.${i}`);
      if (!res.ok) break;
      const log = await res.text();
      log_files.push(log);
    }

    const logs = log_files
      .reverse()
      .join("\n")
      .split("\n")
      .filter((line) => line !== "")
      .map((line) => line.replaceAll("%3A", ":"));

    /* Playground calls */
    callback("Computing number of calls on playground calls...");

    const playground_calls = logs.filter((line) => {
      const splitted_line = line.split(" ");
      if (splitted_line.length < 9) return false;

      const method = splitted_line[5];
      const url = splitted_line[6];
      const status_code = splitted_line[8];

      return (
        method.includes("GET") &&
        status_code === "200" &&
        url.startsWith("/interview") &&
        url.includes("i=docassemble.playground")
      );
    });

    const playgrounds_usage = {};

    for (const call of playground_calls) {
      const date = call.substring(call.indexOf("[") + 1, call.indexOf("+") - 1);

      const start_user_id =
        call.indexOf("i=docassemble.playground") +
        "i=docassemble.playground".length;

      let user_id = "";
      for (const char of call.substring(start_user_id)) {
        if (!char < "0" || char > "9") break;
        user_id += char;
      }

      const start_project_name = start_user_id + user_id.length;
      let project_name = call.substring(
        start_project_name,
        start_project_name + call.substring(start_project_name).indexOf(":")
      );

      if (!project_name) project_name = "default";

      if (!playgrounds_usage.hasOwnProperty(user_id))
        playgrounds_usage[user_id] = {};

      if (!playgrounds_usage[user_id].hasOwnProperty(project_name))
        playgrounds_usage[user_id][project_name] = {
          start_monitoring_date: date,
          number_of_calls: 0,
        };

      playgrounds_usage[user_id][project_name].end_monitoring_date = date;
      playgrounds_usage[user_id][project_name].number_of_calls += 1;
    }

    /* Production calls */
    callback("Computing number of calls on installed projects...");
    const production_usage = {};

    for (const project_name of await get_installed_projects()) {
      production_usage[project_name] = { number_of_calls: 0 };

      for (const call of logs)
        if (
          call.includes(" 200 ") &&
          (call.includes(`GET /start/${project_name}`) ||
            call.includes(`GET /run/${project_name}`) ||
            call.includes(`GET /interview?i=docassemble.${project_name}`))
        ) {
          const date = call.substring(
            call.indexOf("[") + 1,
            call.indexOf("+") - 1
          );

          if (
            !production_usage[project_name].hasOwnProperty(
              "start_monitoring_date"
            )
          )
            production_usage[project_name].start_monitoring_date = date;

          production_usage[project_name].end_monitoring_date = date;
          production_usage[project_name].number_of_calls += 1;
        }
    }

    return { playgrounds_usage, production_usage };
  }

  /* get user list */
  callback("Retrieving user list...");
  const res_user_list = await fetch(`/api/user_list?key=${api_key}`);
  if (!res_user_list.ok) throw Error("Error while retrieving the user list");
  
  const user_list = await res_user_list.json();

  let designer_index = 0;
  const nb_designers = user_list.items.filter(
    (x) => x.privileges.includes("admin") || x.privileges.includes("developer")
  ).length;

  /* get playground project for each user */
  const users = [];
  for (const user of user_list.items) {
    const new_user = {
      user: user.email,
      role: user.privileges,
      id: user.id,
    };

    if (
      new_user.role.includes("admin") ||
      new_user.role.includes("developer")
    ) {
      designer_index += 1;
      // avoid too many api calls by awaiting for each user
      callback(
        `Rerieving playground for ${user.email} (${designer_index}/${nb_designers})...`
      );
      new_user.projects = await get_playground_files(user.id);
    }

    users.push(new_user);
  }

  /* await playground promise */
  callback("Extracting data...");
  for (const user of users.filter((x) => "projects" in x)) {
    
    for (const project of user.projects) {
      project.folders = await project.folders;
      
      for (const folder of project.folders) {
        folder.files = await folder.files;
        
        for (const file of folder.files) 
          file.data = await file.data;
      }
    }
  }

  /* create the user data csv file */
  callback("Creating the user CSV file...");
  let user_csv = `"email";"role";"projects"\n`;
  for (const user of users) {
    user_csv += `"${user?.user}";"${user?.role}";`;
    if ("projects" in user)
      user_csv += `"${user?.projects?.map((x) => x?.name).join(", ")}"`;
    user_csv += "\n";
  }

  /* get installed packages */
  callback("Retrieving installed packages...");
  const installed_projects = await get_installed_projects();

  /* create the installed packages csv file */
  callback("Creating installed packages CSV file...");
  let package_csv = `"installed packages"\n`;
  for (const _package of installed_projects) package_csv += `"${_package}"\n`;

  /* Retrieve logs */
  const { playgrounds_usage, production_usage } =
    await compute_usage_from_logs();

  /* create log monitoring */
  callback("Creating logs CSV files");

  let playground_usage_csv = `"email";"Playground project name";"First logged call date";"Last logged call date";"Number of calls"\n`;
  for (const user_id in playgrounds_usage) {
    const user_email = users.filter(
      (user) => user.id.toString() === user_id.toString()
    )[0]?.user;
    
    if (!user_email) continue;

    for (const project_name in playgrounds_usage[user_id]) {
      const project = playgrounds_usage[user_id][project_name];
      playground_usage_csv += `"${user_email}";"${project_name}";"${project.start_monitoring_date}";"${project.end_monitoring_date}";"${project.number_of_calls}"\n`;
    }
  }

  let production_usage_csv = `"Project name";"First logged call date";"Last logged call date";"Number of calls"\n`;
  for (const project_name in production_usage) {
    const project = production_usage[project_name];
    production_usage_csv += `${project_name};${project.start_monitoring_date};${project.end_monitoring_date};${project.number_of_calls}\n`;
  }

  /* create ZIP */
  callback("Creating ZIP file...");
  const zip = JSZip();
  zip.file("user_list.csv", user_csv);
  zip.file("installed_packages.csv", package_csv);
  zip.file("playgrounds_usage.csv", playground_usage_csv);
  zip.file("production_usage.csv", production_usage_csv);

  for (const user of users.filter((x) => "projects" in x)) {
    const user_folder = zip.folder(user.user);
    for (const project of user.projects) {
      const project_folder = user_folder.folder(project.name);
      for (const folder of project.folders) {
        const folder_folder = project_folder.folder(folder.name);
        for (const file of folder.files.filter(x => x !== null))
          folder_folder.file(file.name, file.data);
      }
    }
  }

  /* download ZIP */
  callback("Downloadig ZIP file...");
  const now = new Date();
  zip.generateAsync({ type: "blob" }).then(function (blob) {
    saveAs(
      blob,
      `docassemble-snapshot-${now.getDate()}_${
        now.getMonth() + 1
      }_${now.getFullYear()}-${now.getHours()}h_${now.getMinutes()}m_${now.getSeconds()}s.zip`
    );
  });
}
