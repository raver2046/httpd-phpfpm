FROM php:7.3.33-fpm-buster

ENV http_proxy http://10.10.10.10:3128
ENV ftp_proxy=http://10.10.10.10:3128
ENV https_proxy=http://10.10.10.10:3128
ENV all_proxy=http://10.10.10.10:3128
ENV HTTP_PROXY=http://10.10.10.10:3128
ENV FTP_PROXY=http://10.10.10.10:3128
ENV HTTPS_PROXY=http://10.10.10.10:3128
ENV ALL_PROXY=http://10.10.10.10:3128


# -----------------------------------------------------------------------------
# Configuration du proxy pour fonctionnement en interne à l'UCBL
# -----------------------------------------------------------------------------
RUN echo "\
export http_proxy=http://10.10.10.10:3128;\
export ftp_proxy=http://10.10.10.10:3128;\
export https_proxy=http://10.10.10.10:3128;\
export all_proxy=http://10.10.10.10:3128;\
export HTTP_PROXY=http://10.10.10.10:3128;\
export FTP_PROXY=http://10.10.10.10:3128;\
export HTTPS_PROXY=http://10.10.10.10:3128;\
export ALL_PROXY=http://10.10.10.10:3128;\
" >> /etc/bash.bashrc

ARG DEBIAN_FRONTEND=noninteractive

RUN echo 'Acquire::http::Proxy "http://10.10.10.10:3128";' > /etc/apt/apt.conf.d/99proxy
RUN apt-get update \
    &&  apt-get install -y --no-install-recommends \
        locales apt-utils  libc-client-dev libkrb5-dev libicu-dev openssl krb5-user ntpdate build-essential procps curl file libldb-dev libssl-dev ldap-utils libldap2-dev  libc-client-dev libkrb5-dev  g++ libpng-dev libxml2-dev libzip-dev libonig-dev libxslt-dev unzip libcurl4-openssl-dev mcrypt libmcrypt4 libmcrypt-dev libgd3 libnss3-tools libgd-dev zlib1g ssl-cert zlib1g-dev

RUN    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen  \
    &&  echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
    &&  locale-gen \
    &&  docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
\
\ 
    &&  docker-php-ext-configure \
            intl  \
    &&  docker-php-ext-install \
            pdo mysqli imap ldap pdo_mysql opcache intl zip calendar dom mbstring gd xsl 

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
                echo 'opcache.memory_consumption=128'; \
                echo 'opcache.interned_strings_buffer=8'; \
                echo 'opcache.max_accelerated_files=4000'; \
                echo 'opcache.revalidate_freq=2'; \
                echo 'opcache.fast_shutdown=1'; \
                echo 'opcache.enable_cli=1'; \
        } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN apt-get clean