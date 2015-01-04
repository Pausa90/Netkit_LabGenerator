#Autore: Andrea Iuliano
#Versione: 2.0


rm lab.conf
for f in *.startup
do
	rm $f
done
for f in */
do
	rm -r $f
done
