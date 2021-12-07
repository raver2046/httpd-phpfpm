FROM debian:buster-slim

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

RUN echo 'Acquire::http::Proxy "http://10.10.10.10:3128";' > /etc/apt/apt.conf.d/99proxy

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y apache2 git locales apt-utils git libapache2-mod-bw libapache2-mod-fcgid software-properties-common libkrb5-3 automake vim sssd-dbus sssd-tools  sssd libtool sssd-krb5 libpam-sss libnss-sss libapache2-mod-qos libapache2-mod-lookup-identity bison apache2-dev flex libapache2-mod-authn-sasl libicu-dev openssl krb5-user ntpdate build-essential procps curl file libldb-dev libssl-dev ldap-utils libldap2-dev  libc-client-dev libkrb5-dev  g++ libpng-dev libxml2-dev libzip-dev libonig-dev libxslt-dev unzip libcurl4-openssl-dev mcrypt libmcrypt4 libmcrypt-dev libgd3 libnss3-tools libgd-dev zlib1g ssl-cert zlib1g-dev 
RUN a2enmod proxy_fcgi
RUN a2enmod authnz_ldap
RUN a2enmod ldap
RUN a2enmod rewrite expires
RUN a2enmod ssl
RUN a2enmod session
RUN a2enmod session_cookie
RUN a2enmod session_crypto
RUN a2enmod auth_form
RUN a2enmod request
RUN a2enmod ratelimit

RUN git clone https://github.com/gssapi/mod_auth_gssapi.git   /tmp/mod_auth_gssapi
RUN /bin/bash -c 'cd /tmp/mod_auth_gssapi ; autoreconf --install --force ; ./configure ; make ; make install'  

COPY ./conf/auth_gssapi_module.conf /etc/apache2/conf-enabled/  
COPY ./conf/mod_qos.conf /etc/apache2/conf-enabled/  
COPY ./conf/mod_reqtimeout.conf /etc/apache2/conf-enabled/  

COPY ./conf/httpd/000-default.conf /etc/apache2/sites-available/000-default.conf


#ici le tls 1.2 permet l'authetification par certificat client :-)
RUN sed -i -e 's/SSLProtocol.*/SSLProtocol -all +TLSv1.2/g' /etc/apache2/mods-enabled/ssl.conf

RUN sed -i -e 's/AllowOverride.*/AllowOverride All/g' /etc/apache2/apache2.conf

#pour le htaccess
#RUN sed -i -e '/<Directory "\/usr\/local\/apache2\/htdocs">/,/<\/Directory>/{s/AllowOverride None/AllowOverride All/}' /etc/apache2/apache2.conf

RUN sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

ENV APACHE_CONFDIR /etc/apache2
ENV APACHE_ENVVARS $APACHE_CONFDIR/envvars

RUN apt-get clean

# logs should go to stdout / stderr
RUN set -ex \
	&& . "$APACHE_ENVVARS" \
	&& ln -sfT /dev/stderr "$APACHE_LOG_DIR/error.log" \
	&& ln -sfT /dev/stdout "$APACHE_LOG_DIR/access.log" \
	&& ln -sfT /dev/stdout "$APACHE_LOG_DIR/other_vhosts_access.log"

CMD /usr/sbin/apache2ctl -D FOREGROUND
