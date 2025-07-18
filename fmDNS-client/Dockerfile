FROM php:7.4-apache

WORKDIR /src

ENV  DNS_Version=7.1.4
ENV  Core_Version=5.3.3

RUN  apt-get update \
  && apt-get -qqy install wget bind9 dnsutils sudo
RUN  wget http://facilemanager.com/download/module/fmdns-$DNS_Version.tar.gz \
  && wget http://facilemanager.com/download/facilemanager-core-$Core_Version.tar.gz \
  && tar -xvf fmdns-$DNS_Version.tar.gz \
  && tar -xvf facilemanager-core-$Core_Version.tar.gz \
  && mv facileManager/client/facileManager /usr/local \
  && ln -s /usr/local/facileManager/www /var/www/html/fM \
  && rm *.tar.gz

COPY config.inc.php /usr/local/facileManager/
COPY entrypoint.sh /
COPY php.ini /usr/local/etc/php/

ENV FACILE_MANAGER_HOST=localhost/
ENV FACILE_MANAGER_AUTHKEY=default
ENV FACILE_CLIENT_SERIAL_NUMBER=
ENV FACILE_CLIENT_LOG_FILE=

RUN  rm -rf /var/lib/apt/lists/* \
  && rm -rf /src/facileManager

CMD ["sudo -u bind named -g"]
ENTRYPOINT ["/entrypoint.sh"]