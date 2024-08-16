#!/bin/bash

echo "Waiting for fmDNS master to become available"
printf '.'
until $(curl --output /dev/null --silent --head --fail $FACILE_MANAGER_HOST); do
	printf '.'
	sleep 1
done
echo

# Set variable defaults if not user provided
if [[ -z $FACILE_MANAGER_HOST ]] ; then FACILE_MANAGER_HOST="localhost" ; fi
if [[ -z $FACILE_MANAGER_AUTHKEY ]] ; then FACILE_MANAGER_AUTHKEY="default" ; fi
if [[ -z $FACILE_CLIENT_SERIAL_NUMBER ]] ; then
	FACILE_CLIENT_SERIAL_NUMBER=$(( $RANDOM % 999999999 + 100000000 ))
	echo "Generated client serial number is $FACILE_CLIENT_SERIAL_NUMBER"
fi

# Creates Bind log file. FM doesn't and it will halt Bind from starting.
if [[ ! -z "$FACILE_CLIENT_LOG_FILE" ]] ; then
	echo "Creating log file: $FACILE_CLIENT_LOG_FILE"
	mkdir -p $(dirname "$FACILE_CLIENT_LOG_FILE")
	touch "$FACILE_CLIENT_LOG_FILE"
	chown bind:bind "$FACILE_CLIENT_LOG_FILE"
fi

echo "Building client config file"
sed -i 's@\$FACILE_MANAGER_HOST@'$FACILE_MANAGER_HOST'@' /usr/local/facileManager/config.inc.php
sed -i 's@\$FACILE_MANAGER_AUTHKEY@'$FACILE_MANAGER_AUTHKEY'@' /usr/local/facileManager/config.inc.php
sed -i 's@\$FACILE_CLIENT_SERIAL_NUMBER@'$FACILE_CLIENT_SERIAL_NUMBER'@' /usr/local/facileManager/config.inc.php

# Connects to server & downloads configs if existing client
output=$( printf "h\n/var/www/html/\n" | php /usr/local/facileManager/fmDNS/client.php install )
echo "$output"
case "$output" in
	"fmDNS is already installed.")
		php /usr/local/facileManager/fmDNS/client.php buildconf
		;;
	*"Welcome to the fmDNS installer."*)
		php /usr/local/facileManager/fmDNS/client.php buildconf
		;;
	*"Installation failed"*)
		exit
		;;
esac

# Make it so that Apache can run sudo commands in order to re-generate the bind9 zone files
cat <<EOF >> /etc/sudoers
Defaults:www-data  !requiretty
Defaults:www-data  !env_reset
www-data ALL=(ALL) NOPASSWD: ALL
EOF

echo "Starting args $@"
case "$@" in
	*"named"*)
		echo "Starting Bind in the foreground"
		service apache2 start
		exec /usr/local/bin/docker-php-entrypoint $@
		;;
	"apache")
		echo "Starting Apache in the foreground"
		service named start
		exec /usr/local/bin/docker-php-entrypoint apache2-foreground
		;;
	*"apache"*)
		echo "Starting Apache in the foreground"
		service named start
		exec /usr/local/bin/docker-php-entrypoint $@
		;;
	*)
		echo "Entrypoint command not recognized"
		;;
esac
