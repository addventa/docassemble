#!/bin/bash

export CONTAINERROLE=":${CONTAINERROLE:-all}:"
export DEBIAN_FRONTEND=noninteractive
export DA_ROOT="${DA_ROOT:-/data/share/docassemble}"
export DA_DEFAULT_LOCAL="local3.10"

if [ "${DAPYTHONMANUAL:-0}" == "0" ]; then
    WSGI_VERSION=`apt-cache policy libapache2-mod-wsgi-py3 | grep '^  Installed:' | awk '{print $2}'`
    if [ "${WSGI_VERSION}" != '4.6.5-1' ]; then
	apt-get -q -y install libapache2-mod-wsgi-py3 &> /dev/null
	ln -sf /usr/lib/apache2/modules/mod_wsgi.so-3.6 /usr/lib/apache2/modules/mod_wsgi.so
    fi
else
    apt-get remove -y libapache2-mod-wsgi-py3 &> /dev/null
    apt-get remove -y libapache2-mod-wsgi &> /dev/null
fi

export DA_ACTIVATE="${DA_PYTHON:-${DA_ROOT}/${DA_DEFAULT_LOCAL}}/bin/activate"
export DA_CONFIG_FILE="${DA_CONFIG:-${DA_ROOT}/config/config.yml}"
source /dev/stdin < <(su -c "source \"$DA_ACTIVATE\" && python -m docassemble.base.read_config \"$DA_CONFIG_FILE\"" www-data)

set -- $LOCALE
export LANG=$1

if [ "${DAHOSTNAME:-none}" == "none" ]; then
    if [ "${EC2:-false}" == "true" ]; then
	export LOCAL_HOSTNAME=`curl -s http://169.254.169.254/latest/meta-data/local-hostname`
	export PUBLIC_HOSTNAME=`curl -s http://169.254.169.254/latest/meta-data/public-hostname`
    else
	export LOCAL_HOSTNAME=`hostname --fqdn`
	export PUBLIC_HOSTNAME="${LOCAL_HOSTNAME}"
    fi
    export DAHOSTNAME="${PUBLIC_HOSTNAME}"
fi

if [ "${BEHINDHTTPSLOADBALANCER:-false}" == "true" ]; then
    a2enmod remoteip
    a2enconf docassemble-behindlb
else
    a2dismod remoteip
    a2disconf docassemble-behindlb
fi

echo -e "# This file is automatically generated" > /etc/apache2/conf-available/docassemble.conf
if [ "${DAPYTHONMANUAL:-0}" == "3" ]; then
    a2dismod wsgi &> /dev/null
    echo -e "LoadModule wsgi_module ${DA_PYTHON:-${DA_ROOT}/${DA_DEFAULT_LOCAL}}/lib/python3.5/site-packages/mod_wsgi/server/mod_wsgi-py35.cpython-35m-x86_64-linux-gnu.so" >> /etc/apache2/conf-available/docassemble.conf
fi
echo -e "WSGIPythonHome ${DA_PYTHON:-${DA_ROOT}/${DA_DEFAULT_LOCAL}}" >> /etc/apache2/conf-available/docassemble.conf
echo -e "Timeout ${DATIMEOUT:-60}\nDefine DAHOSTNAME ${DAHOSTNAME}\nDefine DAPOSTURLROOT ${POSTURLROOT}\nDefine DAWSGIROOT ${WSGIROOT}\nDefine DASERVERADMIN ${SERVERADMIN}\nDefine DAWEBSOCKETSIP ${DAWEBSOCKETSIP}\nDefine DAWEBSOCKETSPORT ${DAWEBSOCKETSPORT}\nDefine DACROSSSITEDOMAINVALUE *\nDefine DALISTENPORT ${PORT:-80}" >> /etc/apache2/conf-available/docassemble.conf
echo "Listen ${PORT:-80}" > /etc/apache2/ports.conf
if [ "${BEHINDHTTPSLOADBALANCER:-false}" == "true" ]; then
    echo "Listen 8081" >> /etc/apache2/ports.conf
    a2ensite docassemble-redirect
fi
if [ "${USEHTTPS:-false}" == "true" ]; then
    echo "Listen 443" >> /etc/apache2/ports.conf
    a2enmod ssl
    a2ensite docassemble-ssl
else
    a2dismod ssl
    a2dissite -q docassemble-ssl &> /dev/null
fi
if [[ $CONTAINERROLE =~ .*:(log):.* ]]; then
    echo "Listen 8080" >> /etc/apache2/ports.conf
fi

function stopfunc {
    echo "Sending stop command"
    /usr/sbin/apache2ctl stop
    echo "Waiting for apache to stop"
    while pgrep apache2 > /dev/null; do sleep 1; done
    echo "Apache stopped"
    exit 0
}

trap stopfunc SIGINT SIGTERM

/usr/sbin/apache2ctl -DFOREGROUND &
wait %1
