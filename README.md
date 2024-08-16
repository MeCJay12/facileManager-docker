# facileManager-docker

This project is not affiliated with WillyXJ/facileManager or facileManager.com. This is an entirely independent project to dockerize the service.

## facileManager Server

### Environment Flags
* MYSQL_HOST = Hostnane of MySQL server or container
* MYSQL_DATABASE = MySQL database name for FM to use
* MYSQL_USER = MySQL username for FM to login with
* MYSQL_PASSWORD = MySQL password for FM to login with
* TZ = Timezone for more readable logs 			default UTC	# optional

### Pre-Requirments
You must have a MySQL database ready for FM manager to connect to. If you do not, run the following for the simplest setup:

```
docker run -d \
	--name MySQL_fM \
	--mount type=bind,src=/path/to/persistant/storage,dst=/var/lib/mysql \
	-e MYSQL_ROOT_PASSWORD=<password> \
	-e MYSQL_DATABASE=facileManager \
	-e MYSQL_USER=facileManager \
	-e MYSQL_PASSWORD=<password> \
	mysql/mysql-server
```

### Running fM Server Container

```
docker run -d \
	--restart=always \
	--name FM \
	-e MYSQL_HOST=MySQL_FM. \
	-e MYSQL_DATABASE=facileManager \
	-e MYSQL_USER=facileManager \
	-e MYSQL_PASSWORD=<password> \
	-e TZ="America/New_York" \ 
	mecjay12/fm
```

## fmDNS Client

### Environment Flags
* FACILE_MANAGER_HOST = Hostnane of fM server or container	default localhost
* FACILE_CLIENT_SERIAL_NUMBER = Client serial number		default random number between 100000000 & 999999999
* 	Without this, the client will reinstall every reboot and service could be inconsistant
* FACILE_MANAGER_AUTHKEY = facileManager authkey		default "default"
* FACILE_CLIENT_LOG_FILE = Path to log file					# optional
* 	If you have a log file configured in Bind/fM, set this or else Bind will fail to start
* TZ = Timezone for more readable logs 				default UTC	# optional

### Running fMDNS Container

```
docker run -d \
	--restart=always \
	--name fmDNS \
	-p 53:53 \
	-p 53:53/udp \
	-p 80:80 \					# Server connects to with http for config updates.
	-h fmDNS.exmaple.com \				# Optional, sets the client name in fM server on install.
	-v /DataDir:/etc/bind/ \			# Optional, caches bind configs so client can start if FM is unreachable.
	-e FACILE_MANAGER_HOST=FM./ \
	-e FACILE_CLIENT_SERIAL_NUMBER=999999999 \
	-e TZ="America/New_York" \			# Optional, sets timezone for easier to read log timestamps.
	mecjay12/fmdns \
	apache						# Optional, Docker logs will show Apache logs instead of Bind logs.
```

## Notes

* Noticed a behavior in the client on 6.0.3 and 6.0.6 where changes are not accepted from the server unless `php /usr/local/facileManager/fmDNS/client.php buildconf` is issued manually once.
* fMDNS client logs will show bind logs by default. To show all DNS requests in these logs add `querylog = yes` to Config -> Options in fM server.
* In some situations, reverse proxies can prevent the server from upgrading or recognizing a rebooting/reinstalling client. The workaround is to bypass the proxy for the clients and upgrades. You can use macvlan, ipvlan, or simply an additional port. Ex.:
```
docker network create \
	-d macvlan \
	--subnet=192.168.0.0/24 \
	--gateway=192.168.0.1 \
	-o parent=eth0 \
	--ip-range 192.168.2.240/29 \
	macvlan
docker network connect \
	macvlan --ip 192.168.0.10 fM
```
* Some Linux distros ship with systemd-resolved which binds to port 53. There are two solutions to this:
	* Follow [these steps](https://www.linuxuprising.com/2020/07/ubuntu-how-to-free-up-port-53-used-by.html) to unbind the service for fmDNS.
	* Use a macvlan/ipvlan so the client listens on a different IP than the host. With this fix, the host won't be able to easily use the container for DNS.
