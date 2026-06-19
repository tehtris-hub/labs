#!/bin/bash
#

## HTTP est bloqué, apparemment Jimmy a joué avec iptables. Vérifiez le pare-feu
# Attention, il vous fait les droits root pour toucher a iptables ;)

???? iptables -? -? -?

# Maintenant que vous avez vu ce qu'il manque, il faut ajouter une règle. 
# Pour rappel HTTP c'est sur le port 80
# sudo iptables -A ????? -p ??? --dport ?? -j ????

# Et HTTPS ?
# Quel type de paquet nous permet de voir que le flux est autorisé ?

