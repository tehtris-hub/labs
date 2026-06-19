#!/bin/bash
##
# @title fix
# Guided instructions to handle the problem
#

echo "Corrigez ce script pour reparer les betises de Cedric" 
# Cedric à defini un mot de passe trop faible pour le compte cedric
# Endiguez la menace et retablissez un etat nominal de securité
# Cedric a ecrit ce script mais il semble ne pas fonctionner, je me demande pourquoi.

# Utilisez la commande usermod pour bloquer le compte
sudo usermod -? cedric

# Utilisez la commande passwd pour definir un nouveau password pour le compte cedric
# Un bon mot de passe doit faire 16 characteres contenir majuscules, minuscules, et caractere speciaux
# nous avons choisi son nouveau mot de passe : fait_1_3ffort,C3dric
sudo passwd c?????

# N'oubliez pas de deverouiller le compte avec la commande usermod.
sudo usermod -? cedric

# Une fois le password defini vous pourrez confirmer que le nouveau mot de passe est bien defini avec le script solution.sh
 
