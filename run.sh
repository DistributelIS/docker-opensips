#!/bin/bash

export HOST_IP=$(ip route get 8.8.8.8 | head -n +1 | tr -s " " | cut -d " " -f 7)
export PUBLIC_IP=$(curl -s http://wtfismyip.com/text)

OPENSIPS_PID=/var/run/opensips/opensips.pid

cd /etc/opensips

if [ -e opensips.cfg.j2 ]; then
	if [ -e opensips.json ]; then
		if [[ opensips.json -nt opensips.cfg || opensips.cfg.j2 -nt opensips.cfg ]]; then
			echo "Regenerating config from template with JSON..."
			/usr/local/bin/j2 opensips.cfg.j2 opensips.json > opensips.cfg
		fi
	else
		if [ opensips.cfg.j2 -nt opensips.cfg ]; then
			echo "Regenerating config from template..."
			/usr/local/bin/j2 opensips.cfg.j2 > opensips.cfg
		fi
	fi
else
	if [ -e opensips.cfg ]; then
		sed -i "s/listen=.*/listen=udp:${HOST_IP}:5060 as ${PUBLIC_IP}:5060/g" /etc/opensips/opensips.cfg
	fi
fi


while : ; do
	echo "Checking on OpenSIPS..."
	sleep 2

	if [ -e ${OPENSIPS_PID} ]; then
		curpid=`cat ${OPENSIPS_PID}`
		if [ -e /proc/$curpid -a /proc/$curpid/exe ]; then

			sipsak -N -D 1 -s sip:nobody@$ipaddr

			if [ $? -ne 0 ]; then
				echo 'WARNING: OpenSIPS is not responding to sipsak' >> /etc/opensips/opensips.log
				kill `cat ${OPENSIPS_PID}`
			else
				continue
			fi
		fi
	fi

	/usr/sbin/opensips -P ${OPENSIPS_PID} -D -f opensips.cfg 1> /dev/stdout 2> /dev/stderr &
done
