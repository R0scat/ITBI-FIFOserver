#!/bin/bash

# config ul
source configServer.conf

if [[ ! -p $fifoServer ]]; then
	echo "Eroare: FIFO-ul serverului nu există!"
	exit 1
fi

# PID-ul clientului
clientPid=$$

# creeaza un fifo personalizat pt raspuns
clientFifo="/tmp/server-reply-$clientPid"
mkfifo $clientFifo

echo "Introdu o comanda: "
read commandName
cerere="BEGIN-REQ [$clientPid: $commandName] END-REQ"

# trimite cererea catre server
echo "$cerere" > $fifoServer
echo "Cererea a fost trimisă serverului: $cerere"

# asteapta raspunsul de la sv
cat $clientFifo

# sterge fifo ul 
rm -f $clientFifo

exit 0
