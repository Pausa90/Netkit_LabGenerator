#Autore: Andrea Iuliano
#Versione: 2.0

NUMROWS=$(wc -l configuration_lab.conf | awk '{print $1}')
I=1
CHARVAL="41" #Valore ascii di A
touch lab.conf

#Per ogni riga
while [ $I -le $NUMROWS ]; do
	
	#Memorizzo la riga
	ROW=$(cat configuration_lab.conf | awk -v FS="\n" -v RS="$" -v V=$I '{print $V}')
	
	if test "$ROW" = ""; then
		
		#Aggiungo una riga vuota a lab.conf, segno che cambio lan
		echo >> lab.conf
		
		#Incremento il carattere per la prossima lan
		let CHARVAL+=1
	
		#Annullo le variabili opzionali associate alla lan
		GW=""
		RIP=""

	else
		
		#Se inizia con ip sto iniziando una nuova lan
		if test "${ROW:0:2}" = "ip"; then #prengo la sottostringa tra 0 e 2
			
			IP=$(echo $ROW | awk '{print $2}' | awk -v FS="/" '{print $1}')
			NETMASK=$(echo $ROW | awk '{print $2}' | awk -v FS="/" '{print "/"$2}')
		
		elif	test "${ROW:0:7}" = "default";	then
					
			GW=$(echo $ROW | awk '{print $2}')

		elif	test "${ROW:0:3}" = "rip"; then
					
			RIP="YES"

		else 			
			#Creo le oppurte variabili affinchè abbia l'ip e la netmask della singola macchina			
			PC=$(echo $ROW | awk -v FS="[" '{print $1}')			
			DEV=$(echo $ROW | awk -v FS="[" '{print $2}' | awk -v FS="]" '{print $1}')
			IPENDTMP=$(echo $ROW | awk -v FS="=" '{print $2}')
			IPEND=$(echo $IPENDTMP | awk '{print $1}')
			IPBEG=$(echo $IP | awk -v FS="." '{print $1"."$2"."$3"."}')
			REALIP=$(echo $IPBEG)$IPEND
			
			CHAR=$(echo -e "\x$CHARVAL") #Stampa i caratteri convertendo in ascii
			#Aggiungo il pc al lab.conf
			echo $(echo $PC)[$(echo $DEV)]=$(echo $CHAR) >> lab.conf

			#Creo la cartella con il suo nome se non è stata ancora creata
			if test ! -d $PC; then
				mkdir $PC
			fi

			#Creo il file .startup se già non esiste
			if test ! -s $PC.startup; then
				touch $PC.startup
			fi
			
			#Aggiungo i parametri relativi ad ifconfig
			echo "ifconfig eth$DEV $REALIP$NETMASK up" >> $PC.startup

			#Aggiungo le rotte statiche se necessarie
			if test ! "$GW" = ""; then

				if test ! "${ROW:0:1}" = "r"; then	
				
					if test ! "${ROW:0:2}" = "as"; then	
				
						GWIP=$(echo $IPBEG)$GW
						echo "route add default gw $GWIP dev eth$DEV" >> $PC.startup
					fi
				fi
			fi

			#Se è un dns controllo se è root
			if test "${ROW:0:2}" = "ns" -o "${ROW:0:3}" = "dns"; then
			
				#Se è il dnsroot memorizzo l'ip
				ZONA=$(echo $ROW | awk '{print $2}')				
				if test "$ZONA" = "root"; then
					
					IPROOT=$(echo $REALIP)
				fi
			fi

			#Se è un as 
			if test "${ROW:0:2}" = "as"; then
				
				#Avvio zebra nello startup se non è stato già fatto
				ZEBRA=$(grep '^/etc/init.d/zebra start' $PC.startup)
				if test "$ZEBRA" = ""; then
					echo "/etc/init.d/zebra start" >> $PC.startup
						
					mkdir -p $PC/etc/zebra
					echo "zebra=yes" > $PC/etc/zebra/daemons
					echo "bgpd=yes" >> $PC/etc/zebra/daemons

					touch $PC/etc/zebra/bgpd.conf
					echo "hostname bgpd" >> $PC/etc/zebra/bgpd.conf	
					echo "password zebra" >> $PC/etc/zebra/bgpd.conf
					echo "enable password zebra" >> $PC/etc/zebra/bgpd.conf
					echo "!" >> $PC/etc/zebra/bgpd.conf
					echo "router bgp NUMAS" >> $PC/etc/zebra/bgpd.conf
					echo "!" >> $PC/etc/zebra/bgpd.conf		
					echo "network NETMASK" >> $PC/etc/zebra/bgpd.conf			
					echo "!" >> $PC/etc/zebra/bgpd.conf		
					echo "neighbor IP remote-as NUMAS" >> $PC/etc/zebra/bgpd.conf
					echo "!" >> $PC/etc/zebra/bgpd.conf		
					echo "log file /var/log/zebra/bgpd.log" >> $PC/etc/zebra/bgpd.conf
					echo "!" >> $PC/etc/zebra/bgpd.conf	
					echo "debug bgp" >> $PC/etc/zebra/bgpd.conf	
					echo "debug bgp events" >> $PC/etc/zebra/bgpd.conf	
					echo "debug bgp filters" >> $PC/etc/zebra/bgpd.conf	
					echo "debug bgp fsm" >> $PC/etc/zebra/bgpd.conf	
					echo "debug bgp keepalives" >> $PC/etc/zebra/bgpd.conf	
					echo "debug bgp updates" >> $PC/etc/zebra/bgpd.conf	
					echo "!" >> $PC/etc/zebra/bgpd.conf	

				fi
	
			fi
			
			#Se serve attivo rip, controllando che siano as o router
			if test "$RIP" = "YES"; then
								
				if test  "${ROW:0:1}" = "r" -o "${ROW:0:2}" = "as"; then	
				
					#Se non è stato già detto, faccio avviare zebra
					ZEBRA=$(grep '^/etc/init.d/zebra start' $PC.startup)
					if test "$ZEBRA" = ""; then

						echo "/etc/init.d/zebra start" >> $PC.startup
					fi
	
					#Se non è stato già detto, creo i demoni
					if test ! -s $PC/etc/zebra/daemons; then
												
						mkdir -p $PC/etc/zebra
						echo "zebra=yes" > $PC/etc/zebra/daemons
					fi
	
					#Se non è stato già annunciata la creazione di ripd la inserisco
					RIPD=$(cat $PC/etc/zebra/daemons | grep '^ripd')
					if test "$RIPD" = ""; then
						echo "ripd=yes" >> $PC/etc/zebra/daemons
					fi
					
					#Creo il demone di rip prestando attenzione alla redistribuzione bgp
					if test ! -s $PC/etc/zebra/ripd; then
												
						echo "hostname ripd" > $PC/etc/zebra/ripd.conf	
						echo "password zebra" >> $PC/etc/zebra/ripd.conf
						echo "enable password zebra" >> $PC/etc/zebra/ripd.conf
						echo "!" >> $PC/etc/zebra/ripd.conf
						echo "router rip" >> $PC/etc/zebra/ripd.conf
						echo "redistribute connected" >> $PC/etc/zebra/ripd.conf		
						#Se è un as inserisce anche redistribute bgp
						if test "${ROW:0:2}" = "as"; then 
							echo "redistribute bgp" >> $PC/etc/zebra/ripd.conf
						fi
						echo "!" >> $PC/etc/zebra/ripd.conf
						echo "network NETMASK" >> $PC/etc/zebra/ripd.conf		
						echo "!" >> $PC/etc/zebra/ripd.conf		
						echo "log file /var/log/zebra/ripd.log" >> $PC/etc/zebra/ripd.conf	
					fi	

				fi
			fi

		fi
	fi
	
	let I+=1
done

#nuovo ciclo sul file per la configurazione dei dns

I=1

#Per ogni riga
while [ $I -le $NUMROWS ]; do

	ROW=$(cat configuration_lab.conf | awk -v FS="\n" -v RS="$" -v V=$I '{print $V}')
	if test "${ROW:0:2}" = "ip"; then #prengo la sottostringa tra 0 e 2
			
		IP=$(echo $ROW | awk '{print $2}' | awk -v FS="/" '{print $1}')
		NETMASK=$(echo $ROW | awk '{print $2}' | awk -v FS="/" '{print "/"$2}')

	else
		
		
		#Ricavo le informazioni relative al nome, alla zona ed all'ip
		PC=$(echo $ROW | awk -v FS="[" '{print $1}')			
		IPENDTMP=$(echo $ROW | awk -v FS="=" '{print $2}')
		IPEND=$(echo $IPENDTMP | awk '{print $1}')
		IPBEG=$(echo $IP | awk -v FS="." '{print $1"."$2"."$3"."}')
		REALIP=$(echo $IPBEG)$IPEND
		ZONA=$(echo $ROW | awk '{print $2}')

		#Se è un web service
		if test "${ROW:0:2}" = "ws"; then

			#Avvio apache2
			echo "/etc/init.d/apache2 start" >> $PC.startup	

			#Inserisco un file html contrastintivo con il nome
			mkdir -p $PC/var/www/
			echo "Benvenuto su $PC" >> $PC/var/www/index.html
		fi
		
		#Se è un dns
		if test "${ROW:0:2}" = "ns" -o "${ROW:0:3}" = "dns"; then
			
			#Attivo bind
			echo "/etc/init.d/bind start" >> $PC.startup
	
			#Creo i file di configurazione in bind
			mkdir -p $PC/etc/bind

			if test "$ZONA" = "root"; then
	
				touch $PC/etc/bind/named.conf
				echo 'zone "." {' >> $PC/etc/bind/named.conf
				echo "type master;" >> $PC/etc/bind/named.conf
				echo 'file "/etc/bind/db.root";' >> $PC/etc/bind/named.conf
				echo "};" >> $PC/etc/bind/named.conf
				
				touch $PC/etc/bind/db.root
				echo '$TTL    60000' >> $PC/etc/bind/db.root
				echo "@               IN      SOA     ROOT-SERVER.    root.ROOT-SERVER. (" >> $PC/etc/bind/db.root
				echo "2006031201 ; serial" >> $PC/etc/bind/db.root
				echo "28800 ; refresh" >> $PC/etc/bind/db.root
				echo "14400 ; retry" >> $PC/etc/bind/db.root
				echo "3600000 ; expire" >> $PC/etc/bind/db.root
				echo "0 ; negative cache ttl" >> $PC/etc/bind/db.root
				echo ")" >> $PC/etc/bind/db.root
				echo "@               IN      NS      ROOT-SERVER." >> $PC/etc/bind/db.root
				echo "ROOT-SERVER.          IN      A      $REALIP" >> $PC/etc/bind/db.root

			#Se non è root
			else
		
				touch $PC/etc/bind/named.conf
				echo "options{" >> $PC/etc/bind/named.conf
				echo "allow-recursion{0/0; };" >> $PC/etc/bind/named.conf
				echo "};" >> $PC/etc/bind/named.conf
				echo 'zone "." {' >> $PC/etc/bind/named.conf
				echo "type hint;" >> $PC/etc/bind/named.conf
				echo 'file "/etc/bind/db.root";' >> $PC/etc/bind/named.conf
				echo "};" >> $PC/etc/bind/named.conf
				echo "zone \"$ZONA\" {" >> $PC/etc/bind/named.conf
				echo "type master;" >> $PC/etc/bind/named.conf
				echo "file \"/etc/bind/db.$ZONA\";" >> $PC/etc/bind/named.conf
				echo "};" >> $PC/etc/bind/named.conf
			
				touch $PC/etc/bind/db.root
				echo ".                   IN  NS    ROOT-SERVER." >> $PC/etc/bind/db.root
				echo "ROOT-SERVER.        IN  A     $IPROOT" >> $PC/etc/bind/db.root

				touch $PC/etc/bind/db.$ZONA
				echo '			$TTL    60000' >> $PC/etc/bind/db.$ZONA
				echo "			@               IN      SOA     dns$ZONA.    root.dns$ZONA. (" >> $PC/etc/bind/db.$ZONA
				echo "			2006031201 ; serial" >> $PC/etc/bind/db.$ZONA
				echo "			28800 ; refresh" >> $PC/etc/bind/db.$ZONA
				echo "			14400 ; retry" >> $PC/etc/bind/db.$ZONA
				echo "			3600000 ; expire" >> $PC/etc/bind/db.$ZONA
				echo "			0 ; negative cache ttl" >> $PC/etc/bind/db.$ZONA
				echo ")" >> $PC/etc/bind/db.$ZONA
				echo "@               IN      NS      dns$ZONA." >> $PC/etc/bind/db.$ZONA
				echo "dns$ZONA.          IN      A      $REALIP" >> $PC/etc/bind/db.$ZONA

			fi
		fi

		if test "${ROW:0:2}" = "pc"; then

			RESOLV=$(echo $ROW | awk '{print $3}')
	
			if test ! "$RESOLV" = ""; then
				#Creo la cartella etc se non c'è
				if test ! -d $PC/etc; then
				
					mkdir $PC/etc
				fi
				#Se ho messo un ip
				if test ! "$PC" = "$RESOLV"; then
				
					echo "nameserver $RESOLV" > $PC/etc/resolv.conf
				
				else
				
					echo "nameserver 127.0.0.1" > $PC/etc/resolv.conf
				
					echo "/etc/init.d/bind start" >> $PC.startup
				
					mkdir -p $PC/etc/bind/
					touch $PC/etc/bind/named.conf
					echo "options{" >> $PC/etc/bind/named.conf
					echo "allow-recursion{0/0; };" >> $PC/etc/bind/named.conf
					echo "};" >> $PC/etc/bind/named.conf
					echo 'zone "." {' >> $PC/etc/bind/named.conf
					echo "type hint;" >> $PC/etc/bind/named.conf
					echo 'file "/etc/bind/db.root";' >> $PC/etc/bind/named.conf
					echo "};" >> $PC/etc/bind/named.conf

					touch $PC/etc/bind/db.root
					echo ".                   IN  NS    ROOT-SERVER." >> $PC/etc/bind/db.root
					echo "ROOT-SERVER.        IN  A     $IPROOT" >> $PC/etc/bind/db.root	

				fi
			fi
		fi

	fi

	let I+=1

done
