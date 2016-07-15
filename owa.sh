#!/bin/bash

show=$1

log() {
	if [ "$show" == "--show" ]; then
		echo "$1"
	fi
	echo "$1" >> owa.log
}

DIR=$(dirname $(realpath $0))
cd $DIR

IFS=" " read OUT usr2 pas2 imp prt fld < output.cnf

while read linea; do
	IFS=" " read CUENTA usr1 pas1 OWA <<< $linea
	log ">>>> $CUENTA: $OWA"
	sed -i "s|davmail.url=.*|davmail.url=${OWA}|" davmail.properties

	pid=$(ps -ef | grep davmail  | sed '/ grep /d' | awk '{print $2}')
	pi2=$(pgrep pop2imap)

	if [ "$pid" != "" ]; then
		log "Detenemos davmail colgado ($pid)"
		kill "$pid"
	fi
	if [ "$pi2" != "" ]; then
		log "Detenemos pop2imap colgado ($pi2)"
		kill "$pi2"
	fi

	START_TIME=$SECONDS

	dat=$(date "+%d/%m/%Y %H:%M")
	log "==== $dat ===="

	./davmail.sh davmail.properties > /dev/null &
	pid=$!
	log "Davmail iniciado con pid=$pid"
	sleep 2

	log "Iniciando pop2imap"

	pop2imap --host1 localhost --port1 1110 --user1 $usr1 --password1 $pas1 --host2 $imp --port2 $prt --user2 $usr2 --password2 $pas2 --folder $fld --ssl2 > pop2imap.log

	log "pop2imap parado (pid=$!)"

	kill "$pid"

	log "Davmail parado"

	int=$(($SECONDS - $START_TIME))
	mig=$(grep "No Message-ID Need Transfer" pop2imap.log | wc -l)
	msg="$mig mails subidos en $int segundos"

	log "$msg"

	if [ $mig -gt 0 ]; then
		echo "$dat - $msg" >> summary.log
	fi

	log ""

done < input.cnf
