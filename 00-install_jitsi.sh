#!/bin/bash
# script para instalar jitsi-meet en ubuntu 20.04

#colores
VERDE="\e[0;32m\033[1m"
ROJO="\e[0;31m\033[1m"
AMARILLO="\e[0;33m\033[1m"
FIN="\033[0m\e[0m"

#Ctrl-C
trap ctrl_c INT
function ctrl_c(){
        echo -e "\n${rojo}Programa Terminado por el usuario ${end}"
        exit 0
}

read -p "Ingresa el dominio para jitsi: " JITSI_HOSTNAME
read -p "Ingresa el nombre para el usuario con permisos para crear meetings: " JITSI_ADMIN
read -s -p "Ingresa el password para ${JITSI_ADMIN}: " JITSI_PASSWORD

echo -e "\n\n${AMARILLO}configurando hostname ${FIN}"
sudo hostnamectl set-hostname "${JITSI_HOSTNAME}"
sudo sed -i 's/127\.0\.1\.1[\t]ubuntu2004\.localdomain/127\.0\.1\.1       jitsi\.cultura\.lab/' /etc/hosts

echo -e "${AMARILLO}\nInstalando llaves prosody ${FIN}"
wget -q https://prosody.im/files/prosody-debian-packages.key -O- | sudo apt-key add -

echo -e "${AMARILLO}Agregando repo prosody ${FIN}"
echo deb http://packages.prosody.im/debian $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list > /dev/null

echo -e "\n${AMARILLO}Instalando llaves jitsi ${FIN}"
curl -s https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'

echo -e "\n${AMARILLO}Agregando repo jitsi ${FIN}"
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null

echo -e "\n${AMARILLO}Actualizando repos + instalando jitsi - prosody + certificados auto-firmados ${FIN}"
sudo apt update; sudo apt install jitsi-meet -y

echo -e "\n${AMARILLO}configurando autenticacion ${FIN}"
sudo sed -i 's/jitsi-anonymous/internal_hashed/' /etc/prosody/conf.avail/"${JITSI_HOSTNAME}".cfg.lua
echo -e "\nVirtualHost 'guest.$(hostname -f)'\n\tauthentication = 'anonymous'\n\tc2s_require_encryption = false" | sudo tee -a /etc/prosody/conf.avail/"${JITSI_HOSTNAME}".cfg.lua

echo -e "\n${AMARILLO}configurando dominio anonimo ${FIN}"
sudo sed -i "s/\/\/ anonymousdomain: 'guest\.example\.com'/anonymousdomain: 'guest\.jitsi\.cultura\.lab'/" /etc/jitsi/meet/"${JITSI_HOSTNAME}"-config.js

echo -e "\n${AMARILLO}configurando jicofo ${FIN}"
sudo touch /etc/jitsi/jicofo/sip-communicator.properties
echo "org.jitsi.jicofo.auth.URL=XMPP:$(hostname -f)" |  sudo tee -a /etc/jitsi/jicofo/sip-communicator.properties

echo -e "\n${VERDE}creando usuario local ${FIN}"
sudo prosodyctl register "${JITSI_ADMIN}" "${JITSI_HOSTNAME}" "${JITSI_PASSWORD}"

echo -e "Reiniciando los servicios"
sudo systemctl restart prosody.service jicofo.service jitsi-videobridge2.service
