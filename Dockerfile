FROM jhpyle/docassemble-os
COPY . /tmp/docassemble/
RUN DEBIAN_FRONTEND=noninteractive TERM=xterm LC_CTYPE=C.UTF-8 LANG=C.UTF-8 \
bash -c \
"apt-get -y update \
&& chsh -s /bin/bash www-data \
&& ln -s /var/mail/mail /var/mail/root \
&& cp /tmp/docassemble/docassemble_webapp/docassemble.wsgi /usr/share/docassemble/webapp/ \
&& cp /tmp/docassemble/Docker/*.sh /usr/share/docassemble/webapp/ \
&& cp /tmp/docassemble/Docker/VERSION /usr/share/docassemble/webapp/ \
&& cp /tmp/docassemble/Docker/pip.conf /usr/share/docassemble/local3.10/ \
&& cp /tmp/docassemble/Docker/config/* /usr/share/docassemble/config/ \
&& cp /tmp/docassemble/Docker/cgi-bin/index.sh /usr/lib/cgi-bin/ \
&& cp /tmp/docassemble/Docker/syslog-ng.conf /usr/share/docassemble/webapp/syslog-ng.conf \
&& cp /tmp/docassemble/Docker/syslog-ng-docker.conf /usr/share/docassemble/webapp/syslog-ng-docker.conf \
&& cp /tmp/docassemble/Docker/docassemble-syslog-ng.conf /usr/share/docassemble/webapp/docassemble-syslog-ng.conf \
&& cp /tmp/docassemble/Docker/apache.logrotate /etc/logrotate.d/apache2 \
&& cp /tmp/docassemble/Docker/nginx.logrotate /etc/logrotate.d/nginx \
&& cp /tmp/docassemble/Docker/docassemble.logrotate /etc/logrotate.d/docassemble \
&& cp /tmp/docassemble/Docker/cron/docassemble-cron-monthly.sh /etc/cron.monthly/docassemble \
&& cp /tmp/docassemble/Docker/cron/docassemble-cron-weekly.sh /etc/cron.weekly/docassemble \
&& cp /tmp/docassemble/Docker/cron/docassemble-cron-daily.sh /etc/cron.daily/docassemble \
&& cp /tmp/docassemble/Docker/cron/docassemble-cron-hourly.sh /etc/cron.hourly/docassemble \
&& cp /tmp/docassemble/Docker/cron/syslogng-cron-daily.sh /etc/cron.daily/logrotatepost \
&& cp /tmp/docassemble/Docker/cron/donothing /usr/share/docassemble/cron/donothing \
&& cp /tmp/docassemble/Docker/docassemble.conf /etc/apache2/conf-available/ \
&& cp /tmp/docassemble/Docker/docassemble-behindlb.conf /etc/apache2/conf-available/ \
&& cp /tmp/docassemble/Docker/docassemble-supervisor.conf /etc/supervisor/conf.d/docassemble.conf \
&& cp /tmp/docassemble/Docker/ssl/* /usr/share/docassemble/certs/ \
&& cp -r /tmp/docassemble/Docker/ssl /usr/share/docassemble/config/defaultcerts \
&& chmod og-rwx /usr/share/docassemble/certs/* \
&& chmod og-rwx /usr/share/docassemble/config/defaultcerts/* \
&& cp /tmp/docassemble/Docker/rabbitmq.config /etc/rabbitmq/ \
&& mkdir /usr/share/docassemble/packages \
&& cp /tmp/docassemble/Docker/packages/* /usr/share/docassemble/packages/ \
&& cp /tmp/docassemble/Docker/config/exim4-router /etc/exim4/conf.d/router/101_docassemble \
&& cp /tmp/docassemble/Docker/config/exim4-filter /etc/exim4/docassemble-filter \
&& cp /tmp/docassemble/Docker/config/exim4-main /etc/exim4/conf.d/main/01_docassemble \
&& cp /tmp/docassemble/Docker/config/exim4-acl /etc/exim4/conf.d/acl/29_docassemble \
&& cp /tmp/docassemble/Docker/config/exim4-update /etc/exim4/update-exim4.conf.conf \
&& cp /tmp/docassemble/Docker/nascent.html /var/www/nascent/index.html \
&& cp /tmp/docassemble/Docker/daunoconv /usr/bin/daunoconv \
&& chmod ogu+rx /usr/bin/daunoconv \
&& update-exim4.conf \
&& chown www-data:www-data /usr/share/docassemble/config \
&& chown www-data:www-data \
   /usr/share/docassemble/config/config.yml.dist \
   /usr/share/docassemble/webapp/docassemble.wsgi \
&& chown -R www-data:www-data \
   /tmp/docassemble \
   /usr/share/docassemble/local3.10 \
   /usr/share/docassemble/log \
   /usr/share/docassemble/files \
&& chmod ogu+r /usr/share/docassemble/config/config.yml.dist \
&& chmod 755 /etc/ssl/docassemble \
&& cd /tmp \
&& wget https://bootstrap.pypa.io/get-pip.py \
&& python3.10 get-pip.py \
&& rm -f get-pip.py \
&& pip install --upgrade virtualenv \
&& echo \"en_US.UTF-8 UTF-8\" >> /etc/locale.gen \
&& locale-gen \
&& update-locale \
&& /usr/bin/python3 -m venv --copies /usr/share/docassemble/local3.10 \
&& source /usr/share/docassemble/local3.10/bin/activate \
&& pip3 install --upgrade pip==23.0 \
&& pip3 install --upgrade wheel==0.38.4 \
&& pip3 install --upgrade mod_wsgi==4.9.4 \
&& pip3 install --upgrade \
   acme==2.2.0 \
   certbot==2.2.0 \
   certbot-apache==2.2.0 \
   certbot-nginx==2.2.0 \
   certifi==2022.12.7 \
   cffi==1.15.1 \
   charset-normalizer==3.0.1 \
   click==8.1.3 \
   ConfigArgParse==1.5.3 \
   configobj==5.0.8 \
   cryptography==39.0.1 \
   distro==1.8.0 \
   idna==3.4 \
   joblib==1.2.0 \
   josepy==1.13.0 \
   nltk==3.8.1 \
   parsedatetime==2.6 \
   pycparser==2.21 \
   pyOpenSSL==23.1.1 \
   pyparsing==3.0.9 \
   pyRFC3339==1.1 \
   python-augeas==1.1.0 \
   pytz==2022.7.1 \
   regex==2022.10.31 \
   requests==2.28.2 \
   requests-toolbelt==0.10.1 \
   six==1.16.0 \
   tqdm==4.64.1 \
   urllib3==1.26.14 \
   zope.component==5.1.0 \
   zope.event==4.6 \
   zope.hookable==5.4 \
   zope.interface==5.5.2 \
   ./../usr/share/docassemble/packages/s4cmd-2.1.2-py3-none-any.whl \
&& pip3 install \
   /tmp/docassemble/docassemble \
   /tmp/docassemble/docassemble_base \
   /tmp/docassemble/docassemble_demo \
   /tmp/docassemble/docassemble_webapp \
&& mv /etc/crontab /usr/share/docassemble/cron/crontab \
&& ln -s /usr/share/docassemble/cron/crontab /etc/crontab \
&& mv /etc/cron.daily/apache2 /usr/share/docassemble/cron/apache2 \
&& ln -s /usr/share/docassemble/cron/apache2 /etc/cron.daily/apache2 \
&& mv /etc/cron.daily/exim4-base /usr/share/docassemble/cron/exim4-base \
&& ln -s /usr/share/docassemble/cron/exim4-base /etc/cron.daily/exim4-base \
&& mv /etc/syslog-ng/syslog-ng.conf /usr/share/docassemble/syslogng/syslog-ng.conf \
&& ln -s /usr/share/docassemble/syslogng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf \
&& cp /usr/share/docassemble/local3.10/lib/python3.10/site-packages/mod_wsgi/server/mod_wsgi-py310.cpython-310-x86_64-linux-gnu.so /usr/lib/apache2/modules/mod_wsgi.so-3.10 \
&& pip3 uninstall --yes mysqlclient MySQL-python &> /dev/null \
&& python3.10 -m nltk.downloader -d /usr/local/share/nltk_data all \
&& cp /usr/share/docassemble/local3.10/lib/python3.10/site-packages/s4cmd.py /usr/share/s4cmd/ \
&& chown -R www-data:www-data \
   /usr/share/docassemble/local3.10 \
   /usr/share/docassemble/log \
   /usr/share/docassemble/files \
&& usermod --shell /bin/bash www-data \
&& rm -f /etc/cron.daily/apt-compat \
&& sed -i -e 's/^\(daemonize\s*\)yes\s*$/\1no/g' -e 's/^bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf \
&& sed -i -e 's/#APACHE_ULIMIT_MAX_FILES/APACHE_ULIMIT_MAX_FILES/' -e 's/ulimit -n 65536/ulimit -n 8192/' /etc/apache2/envvars \
&& sed -i '/session    required     pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/cron \
&& LANG=en_US.UTF-8 \
&& a2dismod ssl \
; a2enmod rewrite \
; a2enmod xsendfile \
; a2enmod proxy \
; a2enmod proxy_http \
; a2enmod proxy_wstunnel \
; a2enmod headers \
; a2enconf docassemble \
; echo 'export TERM=xterm' >> /etc/bash.bashrc"

USER www-data
RUN bash -c \
"source /usr/share/docassemble/local3.10/bin/activate \
&& python /tmp/docassemble/Docker/nltkdownload.py \
&& cd /var/www/nltk_data/corpora \
&& unzip -o wordnet.zip \
&& unzip -o omw-1.4.zip"

USER root
RUN rm -rf /tmp/docassemble

EXPOSE 80 443 9001 514 25 465 8080 8081 8082 5432 6379 4369 5671 5672 25672
ENV \
CONTAINERROLE="all" \
LOCALE="en_US.UTF-8 UTF-8" \
TIMEZONE="America/New_York" \
EC2="" \
S3ENABLE="" \
S3BUCKET="" \
S3ACCESSKEY="" \
S3SECRETACCESSKEY="" \
S3REGION="" \
DAHOSTNAME="" \
USEHTTPS="" \
USELETSENCRYPT="" \
LETSENCRYPTEMAIL="" \
BEHINDHTTPSLOADBALANCER="" \
DBHOST="" \
LOGSERVER="" \
REDIS="" \
RABBITMQ="" \
DASUPERVISORUSERNAME="" \
DASUPERVISORPASSWORD=""

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
