#!/bin/bash

## Votre boss vous a envoyé un document de la plus haute importance 
# (c'était marqué dans le mail). Sauf qu'il est chiffré, zut. 
# Le connaissant bien, vous savez que le mot de passe est l'un des suivants :
# - Aniki<3
# - BGduWeb25
# - Urt1ka1r3

# En utilisant OpenSSL, trouver le bon mot de passe, et découvrer le message 
# de votre patron.

openssl enc -? -?????? -in Ultra_important_secret.pdf -out Ultra_important.pdf

