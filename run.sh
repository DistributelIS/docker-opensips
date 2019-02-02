#/bin/bash

## Start script for an OpenSIPS Container running on a Docker Host.
##     Mario Stoccc <maro.stocco@thinktel.ca>
##     February 1, 2018
##
## OpenSIPS is expected to run with host networking; meaning this
## container’s network stack is not isolated from the Docker host.
## Instead, we separate each OpenSIPS container by assigning it a
## unique IP address and setting the "listen" global parameter.
##
## Before we begin, we need an error free OpenSIPS configuration file
## and a check that no other node is using the IP address in the the
## configuration file.


/usr/sbin/opensips -c -f /etc/opensips/opensips.cfg > /tmp/config-check 2>&1
configcheck=$(cat /tmp/config-check)
if [[ $configcheck == *'CRITICAL'* ]]; then
	grep CRIT /tmp/config-check
	echo 'OpenSIPS not started because of errors in opensips.cfg'
	exit;
fi

ipaddr="$(grep -m 1 -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' <<< "$configcheck")"
if [ $ipaddr != '' ]; then
	if [ $ipaddr == '127.0.0.1' ]; then
		echo 'OpenSIPS not started because you are using the stock opensips.cfg'
		exit;
	fi

	ipcheck=$(ping -c 2 $ipaddr)
	if [[ $ipcheck == *'100% packet loss'* ]]; then
		/usr/sbin/opensips -f /etc/opensips/opensips.cfg
		while : ; do
			sleep 3
			running=$(pgrep opensips)
			if [ "$running" == "" ]; then
				echo 'OBITUARY: OpenSIPS has died' >> /etc/opensips/log/opensips.log
				exit
			fi
		done
	fi
	echo OpenSIPS not started because $ipaddr is in use.
	exit
fi

echo OpenSIPS not started because $ipaddr not defined.
exit

