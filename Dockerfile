FROM ubuntu-systemd:15.04

# setup locale and timezone
RUN locale-gen en_US.UTF-8 sl_SI.UTF-8 \
 && update-locale LANG=en_US.UTF-8 \
 \
 && echo "Europe/Ljubljana" > /etc/timezone \
 && dpkg-reconfigure tzdata

# system packages
ADD etc/systemd/system/regenerate-sshd.service /etc/systemd/system/regenerate-sshd.service

RUN apt-get update -qq && apt-get install -y \
    msmtp-mta \
    ubuntu-minimal \
    unattended-upgrades \
    openssh-server \
 \
 && sed -i 's@^//\(Unattended-Upgrade::Mail\)@\1@' /etc/apt/apt.conf.d/50unattended-upgrades \
 \
 && rm -f /etc/ssh/ssh_host_* \
 && systemctl enable regenerate-sshd

# web server
RUN apt-get update -qq && apt-get install -y \
    apache2 \
    libapache2-mod-security2 \
    libapache2-mod-xsendfile

ADD etc/apache2/conf-available/allow-srv.conf /etc/apache2/conf-available/allow-srv.conf
ADD etc/apache2/mods-available/mpm_event.conf /etc/apache2/mods-available/mpm_event.conf
ADD etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
ADD etc/modsecurity/modsecurity.conf /etc/modsecurity/modsecurity.conf
ADD etc/systemd/system/populate-srv.service /etc/systemd/system/populate-srv.service
ADD var/www /var/www

RUN a2dismod mpm_prefork mpm_worker \
 && a2enmod mpm_event \
 \
 && a2enconf allow-srv \
 && systemctl enable populate-srv

# user packages
RUN apt-get update -qq && apt-get install -y \
    aptitude \
    bash \
    dnsutils \
    git \
    less \
    man-db \
    manpages \
    mariadb-client \
    nano \
    openssh-client \
    p7zip-full \
    p7zip-rar \
    rename \
    rsync \
    screen \
    sudo \
    subversion \
    vim \
    wget

# C/C++
#RUN pt-get update -qq && apt-get install -y \
#    build-essential \
#    gcc \
#    manpages-dev \

# Java
#RUN apt-get update -qq && apt-get install -y \
#    maven \
#    openjdk-7-jre \
#    openjdk-7-jdk \

# Python
ADD etc/python/debian_config /etc/python/debian_config

RUN apt-get update -qq && apt-get install -y \
    python \
    python-doc \
    python-pip \
    python-virtualenv
    #libapache2-mod-uwsgi
    #uwsgi

# PHP
ADD etc/apache2/conf-available/php5-fpm.conf /etc/apache2/conf-available/php5-fpm.conf

RUN apt-get update -qq && apt-get install -y \
    libapache2-mod-fastcgi \
    libjs-cropper \
    libjs-mediaelement \
    libphp-phpmailer \
    php-getid3 \
    php-pear \
    php5-fpm \
    php5-json \
    php5-gd \
    php5-mcrypt \
    php5-mysql \
    php5-pgsql \
    php5-xcache \
 \
 && sed -i 's/^;\?\(cgi\.fix_pathinfo\) \?=.*/\1=0/' /etc/php5/fpm/php.ini \
 && sed -i 's/^;\?\(pm\.start_servers\) \?=.*/\1 = 1/' /etc/php5/fpm/pool.d/www.conf \
 && sed -i 's/^;\?\(pm\.max_requests\) \?=.*/\1 = 500/' /etc/php5/fpm/pool.d/www.conf \
 \
 && a2enmod actions fastcgi alias \
 && a2enconf php5-fpm

EXPOSE 22

EXPOSE 80

VOLUME ["/home"]

VOLUME ["/srv"]
