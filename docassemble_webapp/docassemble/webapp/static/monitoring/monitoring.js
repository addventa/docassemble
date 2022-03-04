export async function launch_monitoring(api_key) {
    console.log('hello from monitoring ' + api_key)
    
    async function get_projects(user_id) {
      let url = `/api/playground/project?key=${api_key}&user_id=${user_id}`;
      const res_projects = await fetch(url);
      return res_projects.json();
    }
    
    async function get_files_list(user_id, folder, project = "default") {
      let url = `/api/playground?key=${api_key}&user_id=${user_id}&folder=${folder}`;
      if (project !== "default") url += `&project=${project}`;
      const res_files_list = await fetch(url);
      return res_files_list.json();
    }
    
    async function get_file(user_id, folder, filename, project = "default") {
      let url = `/api/playground?key=${api_key}&user_id=${user_id}&folder=${folder}&filename=${filename}`;
      if (project !== "default") url += `&project=${project}`;
      const res_file = await fetch(url);
      return res_file.blob();
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
    
    /* get user list */
    const res_user_list = await fetch(`/api/user_list?key=${api_key}`);
    const user_list = await res_user_list.json();
    
    /* get playground project for each user */
    const users = [];
    for (const user of user_list.items) {
      const new_user = {
        user: user.email,
        role: user.privileges,
      };
    
      if (new_user.role.includes("admin") || new_user.role.includes("developer"))
        new_user.projects = get_playground_files(user.id);
    
      users.push(new_user);
    }
    
    /* await playground promise */
    for (const user of users.filter((x) => "projects" in x)) {
      user.projects = await Promise.all(await user.projects);
      for (const project of user.projects) {
        project.folders = await project.folders;
        for (const folder of project.folders) {
          folder.files = await folder.files;
          for (const file of folder.files) file.data = await file.data;
        }
      }
    }
    
    /* create the user data csv file */
    let user_csv = `"email";"role";"projects"\n`;
    for (const user of users) {
      user_csv += `"${user.user}";"${user.role}";`;
      if ("projects" in user)
        user_csv += `"${user.projects.map((x) => x.name).join("\n")}"`;
      user_csv += "\n";
    }
    
    /* get installed packages */
    const res_packages = await fetch(`/api/package?key=${api_key}`);
    const packages = await res_packages.json();
    const installed_projects = packages
      .filter((x) => x.type === "zip")
      .map((x) => x.name.replace("docassemble.", ""));
    
    /* create the installed packages csv file */
    let package_csv = `"installed packages"\n`;
    for (const _package of installed_projects) package_csv += `"${_package}"\n`;
    
    /* create ZIP */
    const zip = JSZip();
    zip.file("user_list.csv", user_csv);
    zip.file("installed_packages.csv", package_csv);
    
    for (const user of users.filter((x) => "projects" in x)) {
      const user_folder = zip.folder(user.user);
      for (const project of user.projects) {
        const project_folder = user_folder.folder(project.name);
        for (const folder of project.folders) {
          const folder_folder = project_folder.folder(folder.name);
          for (const file of folder.files) folder_folder.file(file.name, file.data);
        }
      }
    }
    
    /* download ZIP */
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