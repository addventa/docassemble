FROM debian:latest

RUN echo "deb http://debian.cc.lehigh.edu/debian jessie main" > /etc/apt/sources.list && apt-get clean && apt-get update && apt-get -y install python python-dev python-virtualenv wget unzip git locales pandoc texlive texlive-latex-extra apache2 postgresql libapache2-mod-wsgi libapache2-mod-xsendfile  poppler-utils libffi-dev libffi6 libjs-jquery imagemagick gcc supervisor libaudio-flac-header-perl libaudio-musepack-perl libmp3-tag-perl libogg-vorbis-header-pureperl-perl perl make libvorbis-dev libcddb-perl libinline-perl libcddb-get-perl libmp3-tag-perl libaudio-scan-perl libaudio-flac-header-perl libparallel-forkmanager-perl libav-tools automake autoconf automake1.11 libjpeg-dev zlib1g-dev libpq-dev
RUN cd /tmp && git clone git://git.code.sf.net/p/pacpl/code pacpl-code && cd pacpl-code && ./configure; make && make install && cd ..
RUN mkdir -p /usr/share/docassemble/local /usr/share/docassemble/webapp /usr/share/docassemble/files /var/www/.pip && chown www-data.www-data /var/www/.pip && chsh -s /bin/bash www-data
COPY docassemble_webapp/docassemble.wsgi /usr/share/docassemble/webapp/
COPY Docker/initialize.sh /usr/share/docassemble/webapp/
COPY Docker/config.yml /usr/share/docassemble/
COPY Docker/apache.conf /etc/apache2/sites-available/000-default.conf
COPY Docker/docassemble.conf /etc/apache2/conf-available/
COPY Docker/docassemble-supervisor.conf /etc/supervisor/conf.d/docassemble.conf
RUN chown -R www-data.www-data /usr/share/docassemble && chmod ogu+r /usr/share/docassemble/config.yml

USER www-data
RUN virtualenv /usr/share/docassemble/local
RUN cd /tmp && source /usr/share/docassemble/local/bin/activate && pip install --upgrade us 3to2 boto guess-language-spirit html2text mdx_smartypants titlecase pygeocoder beautifulsoup4 psycopg2 cffi bcrypt speaklater pillow wtforms werkzeug rauth simplekv Flask-KVSession flask-user pypdf flask flask-login flask-sqlalchemy Flask-WTF babel blinker sqlalchemy Pygments mako pyyaml python-dateutil setuptools httplib2 && git clone https://github.com/nekstrom/pyrtf-ng && cd pyrtf-ng && python setup.py install && cd /tmp && wget https://www.nodebox.net/code/data/media/linguistics.zip && unzip linguistics.zip -d /usr/share/docassemble/local/lib/python2.7/site-packages/ && rm linguistics.zip && mkdir -p /tmp/docassemble
COPY . /tmp/docassemble/
RUN cd /tmp/docassemble && ./compile.sh

USER root
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN locale-gen
RUN update-locale LANG=en_US.UTF-8
RUN a2enmod ssl
RUN a2enmod wsgi
RUN a2enmod xsendfile
RUN a2enconf docassemble
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
EXPOSE 80
EXPOSE 443
EXPOSE 9001

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
