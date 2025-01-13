#!/bin/bash

cd fisierIntermediar

#while true; do
	read input < FIFO.txt
	#comandaClient= grep -o ': [^ ,]\+' < FIFO.txt
	comandaClient= awk -F': |] END-REQ' '{print $2}' <<< "$input"
	pidClient= awk -F'BEGIN-REQ |:' '{print $2}' <<< "$input"
	expr 
	echo $comandaClient
	echo $pidClient
	echo $input
#done

#rmdir fisierIntermediar
cd ..

exit 0
