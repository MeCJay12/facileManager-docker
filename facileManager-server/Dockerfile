FROM php:7.4-apache

ENV Version=4.5.0
WORKDIR /src

RUN	apt-get update \
	&& apt-get -qqy install wget libldb-dev libldap2-dev ssh iputils-ping bind9-utils \
	&& wget http://facilemanager.com/download/facilemanager-complete-$Version.tar.gz \
	&& tar -xvf facilemanager-complete-$Version.tar.gz \
	&& mv facileManager/server/* /var/www/html/ \
	&& mkdir /fm_tmp/ \
	&& chown -R www-data:www-data /fm_tmp/ \
    && chown -R www-data:www-data /var/www/html/ \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
	&& docker-php-ext-install mysqli ldap \
	&& a2enmod rewrite dump_io 

COPY config.inc.php /var/www/html/
COPY php.ini /usr/local/etc/php/php.ini
COPY init.php.patch /var/www/html/fm-includes/

RUN patch /var/www/html/fm-includes/init.php /var/www/html/fm-includes/init.php.patch

RUN	rm -rf /var/lib/apt/lists/* \
	&& rm -rf /src/facileManager
