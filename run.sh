#!/bin/bash

HOST_IP=$(ip route get 8.8.8.8 | head -n +1 | tr -s " " | cut -d " " -f 7)
PUBLIC_IP=$(curl http://wtfismyip.com/text)

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

service rsyslog start

/usr/sbin/opensipsctl start

tail -f /var/log/opensips.log
