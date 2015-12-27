#!/bin/bash
set -euo pipefail

retry(){
	until "$@"; do
		echo "$@ failed, delaying randomly"
		sleep ${RANDOM:1:1}
	done
}

submit(){
	retry git add "$1"
	retry git commit -m "Updating $1"
	retry git push
}

scanloop(){
	while true; do
		~/bin/ftp.list "$1"
		submit "$1"
		sleep 3600
	done
}

while true; do 
	echo "$(date) Starting scan"
	nmap -PN -p 21 -vv -oG scan.gnmap -T5 -n 151.217.0/16 >/dev/null
	submit scan.gnmap
	echo "$(date) Scan ended"
	for ip in $(awk '/21\/open/{print $2}' scan.gnmap ); do
		if [ ! -e "$ip".log ]; then
			echo "Starting scan loop for $ip"
			scanloop "$ip" &
		fi
	done
	sleep 3600
done
