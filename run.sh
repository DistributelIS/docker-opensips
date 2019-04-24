#!/bin/bash

HOST_IP=$(ip route get 8.8.8.8 | head -n +1 | tr -s " " | cut -d " " -f 7)
PUBLIC_IP=$(curl -s http://wtfismyip.com/text)

if [ -n "$OPENSIPS_IP" ]; then
		HOST_IP=${OPENSIPS_IP}
		PUBLIC_IP=${OPENSIPS_IP}
	else
		HOST_IP=$(ip route get 8.8.8.8 | head -n +1 | tr -s " " | cut -d " " -f 7)
		PUBLIC_IP=$(curl -s http://wtfismyip.com/text)
fi

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

WORKED_ONCE=0

while : ; do
	if [ -e ${OPENSIPS_PID} ]; then
		curpid=`cat ${OPENSIPS_PID}`
		if [ -e /proc/$curpid -a /proc/$curpid/exe ]; then

			/usr/bin/sipsak -D 1 -s sip:health@${HOST_IP}

			if [ $? -ne 0 ]; then
				if [ ${WORKED_ONCE} -ne 0 ]; then
					echo 'Health check failed, killing OpenSIPS'
					kill `cat ${OPENSIPS_PID}`
				else
					continue
				fi
			else
				WORKED_ONCE=1
				continue
			fi
		fi
	fi

	/usr/sbin/opensips -E -F -f opensips.cfg 1> /dev/stdout 2> /dev/stderr &
	pid=$!
	echo ${pid} > ${OPENSIPS_PID}

	sleep 30
done
