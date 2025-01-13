#!/bin/bash

# incarca config ul
source configServer.conf

# creeaza fifo ul serverului daca nu exista
if [[ ! -p $fifoServer ]]; then
	mkfifo  $fifoServer
fi

echo "Serverul este pornit pe $fifoServer..."

# while infinit :P
while true; do
	# citeste cererea din fifo ul serverului
	if read -r cerere <  $fifoServer; then
		if [[ $cerere =~ BEGIN-REQ\ \[([0-9]+):\ ([a-zA-Z0-9_-]+)\]\ END-REQ ]]; then
			clientPid="${BASH_REMATCH[1]}"
			commandName="${BASH_REMATCH[2]}"
			clientFifo="/tmp/server-reply-$clientPid"
			
			echo "Cerere primita de la PID=$clientPid pentru comanda '$commandName'."
			
			# creeaza fifo ul clientului
			if [[ ! -p $clientFifo ]]; then
            			mkfifo $clientFifo
			fi

            		# generează raspunsul și il scrie în fifo
            		man "$commandName" > "$clientFifo"
            		
			# sterge fifo clientului
            		rm -f $clientFifo
		fi
   	 fi
done

rm $fifoServer

exit 0
