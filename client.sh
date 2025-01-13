#!/bin/bash

read comanda
clientPid=$$
cerere="BEGIN-REQ [${clientPid}: ${comanda}] END-REQ"

mkdir fisierIntermediar
cd fisierIntermediar/
touch FIFO.txt
echo $cerere > FIFO.txt

exit 0

