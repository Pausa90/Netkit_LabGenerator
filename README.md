#Netkit_LabGenerator

Netkit_LabGenerator is an unofficial automatic tool for [Netkit] use.

This project resulted from the desire to reduce the time of creation (and modification) of a simulated laboratory, during the university course [Infrastrutture delle Reti di Calcolatori]. 

## How to use it

The project contain a detailed instructions in italian located in "istruzioni per l'uso.txt".

The script creates a simulated network by reading the contens of "configuration_lab.conf", described by a precise syntax. The project contain a sample file.

One written the configuration file, start "lab_generator.sh" and netkit later.

To changes the lab description just clean the netkit's files through "clean.sh", edit the configuration file and repeat the procedure.

The script does NOT have any form of intelligence, therefore it only create one sketch of the file "bgpd.conf", wich requires modification.























[Netkit]: http://wiki.netkit.org/index.php/Main_Page
[Infrastrutture delle Reti di Calcolatori]: http://www.dia.uniroma3.it/~impianti/HomePage12-13/index_irc.html
