# FIFOserver

## Introducere 

Acest proiect implementează un sistem client-server în Linux utilizând limbajul Bash și fișiere FIFO (First In, First Out) drept canale de comunicare între clienți și server. Scopul proiectului este să faciliteze accesul la informațiile din paginile de manual ale comenzilor Linux. 

## Specificații tehnice 

- Fișierul FIFO bine-cunoscut (well-known FIFO) 
- Serverul utilizează un fișier FIFO cu un nume bine-cunoscut pentru a primi cererile clienților. 

- Locația și numele acestui fișier FIFO sunt configurabile printr-un fișier de configurare. 

## Structura cererilor clientului 

Cererile clienților au următorul format: 

    BEGIN-REQ (client-pid: command-name) END-REQ 

unde avem:
- client-pid: ID-ul de proces al clientului. 
- command-name: Numele comenzii Linux pentru care se dorește informația din pagina de manual. 

## Comportamentul serverului 

- Primirea cererilor 
- Serverul citește cererile clienților din FIFO-ul bine-cunoscut. 
- Prelucrarea cererii 
- Serverul extrage din cerere PID-ul clientului și numele comenzii. 
- Apelează comanda man command-name pentru a obține informațiile din pagina de manual. 
- Transmiterea răspunsului 
- Serverul creează un fișier FIFO personalizat pentru fiecare client, conform formatului: ```/tmp/server-reply-ZZZZ ``` ( Unde ZZZZ reprezintă PID-ul ) clientului. 
- Răspunsul (conținutul paginii de manual) este transmis prin acest fișier FIFO personalizat. 

## Comportamentul clientului 
Clientul creează cererea conform formatului specificat și o trimite serverului prin FIFO-ul bine-cunoscut.  Acesta așteaptă răspunsul în fișierul FIFO personalizat creat de server. După ce conținutul paginii de manual este afișat pe ecran, clientul șterge fișierul FIFO personal. 

## Dificultăți întâmpinate: 

- Utilizarea mecanismelor Pipe 
- Gestionarea fișierelor FIFO 
- Încărcarea fișierului de configurare 

## Explicarea codului: 

1.server.sh 
```sh
#!/bin/bash 
source configServer.conf	 
```
Incarcă și execută conținutul fișierului configServer.conf în aceași sesiune de shell ca script-ul principal, astfel variabilele, funcțiile și alte resurse definite în fișier devin disponibile imediat în script-ul prinicipal, fără a fi nevoie de alta configurare. De asemenea tot conținutul fișierului poate fi folosit în mai multe script-uri pentru variabile sau pentru funcții. Așadar, citește variabilele de configurare din fișier și permite folosirea acestora în script-ul curent.  
```sh
if [[ ! -p $fifoServer ]]; then				 
```
Verifică dacă server-ul nu există, caz în care îl creeaza, -p verifică dacă un fișier este un FIFO (named pipe), necesar pentru comunicarea între doua procese care rulează independent pe sistemul de operare. În cazul de față, permite schimbul de mesaje între server și client. Față de un pipe obișnuit, un FIFO facilitează sincronizarea mesajelor: Clientul scrie, mesajul intră în FIFO, server-ul citește, preia mesajul și îl procesează. FIFO blochează scrierea sau citirea dacă unul dintre procese nu este pregătit, prevenind pierderea datelor.	 
```sh
mkfifo  $fifoServer 

fi 

echo "Serverul este pornit pe $fifoServer..." 

while true; do	
```	
Menține server-ul activ pentru a procesa cereri continuu printr-o buclă infinită 
```sh
if read -r cerere <  $fifoServer; then 
```
Citește cererea trimisă de client pe server, se folosește –r pentru a preveni interpretarea caracterelor speciale 
```sh
if [[ $cerere =~ BEGIN-REQ\ \[([0-9]+):\ ([a-zA-Z0-9_-]+)\]\ END-REQ ]]; then 
```
Validarea și parsarea cererii, și extragerea PID-ului clientului și a numelui comenzii solicitate 
```sh
clientPid="${BASH_REMATCH[1]}" 
commandName="${BASH_REMATCH[2]}" 
clientFifo="/tmp/server-reply-$clientPid" 
```
Extragerea variabelelor (PID-ul clientului, numele comenzii, FIFO-ul de reply pentru client 
```sh
echo "Cerere primita de la PID=$clientPid pentru comanda '$commandName'." 
```
Afișarea pe ecran a confirmării înregistrării cererii 
```sh
if [[ ! -p $clientFifo ]]; then  
        mkfifo $clientFifo 
fi 
```
Crearea Fifo-ului in cazul in care nu exista.
```sh
man "$commandName" > "$clientFifo" 	
```                 
Rulează comanda man pentru comanda cerută și scrie rezultatul în FIFO-ul clientului 
```sh
rm -f $clientFifo
```									 
Șterge FIFO-ul clientului după ce răspunsul a fost trimis. Evită acumularea de fișiere temporare 							 
```sh
rm $fifoServer 
```
Șterge FIFO-ul server-ului la închiderea scriptului pentru a preveni fișierele rămase 

1.client.sh 
```sh
if [[ ! -p $fifoServer ]]; then 
    echo "Eroare: FIFO-ul serverului nu există!" 
    exit 1 
fi 
```
Verifică dacă FIFO-ul ($fifoServer) există și este valid, în caz contrar afișând un mesaj de eroare și terminând execuția script-ului. 
```sh
clientPid=$$ 
```
Variabila specială $$ reține PID-ul (Process ID) procesului curent. este folosit pentru a crea un FIFO unic pentru acest client. 
```sh
clientFifo="/tmp/server-reply-$clientPid" 
mkfifo $clientFifo 
```

definește un FIFO temporar, unic pentru client, folosind PID-ul său și îl creează cu mkfifo 
```sh
echo "Introdu o comanda: " 
read commandName 
cere comanda de la utilizator 
cerere="BEGIN-REQ [$clientPid: $commandName] END-REQ" 
```
formateaza cererea ce urmeaza să fie trimisă server-ului 
```sh
echo "$cerere" > $fifoServer 
echo "Cererea a fost trimisă serverului: $cerere" 
```
Trimite mesajul format în FIFO-ul serverulu și afișează un mesaj de confirmare că cererea a fost trimisă. 
```sh
cat $clientFifo 
```
Scriptul citește răspunsul de la server din FIFO-ul personalizat al clientului ($clientFifo). Comanda cat blochează execuția până când serverul scrie un răspuns în FIFO. 
```sh
rm -f $clientFifo 
```
Șterge FIFO-ul personalizat pentru a evita fișierele temporare inutile. 
