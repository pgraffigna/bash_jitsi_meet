#!/bin/bash
# Script para instalar Jitsi Meet en Ubuntu 22.04
#
# Autor: Pablo Graffigna
# URL: www.linkedin.com/in/pablo-graffigna
#

# Colores
VERDE="\e[0;32m\033[1m"
ROJO="\e[0;31m\033[1m"
AMARILLO="\e[0;33m\033[1m"
FIN="\033[0m\e[0m"

# Ctrl-C
trap ctrl_c INT
function ctrl_c(){
    echo -e "\n${ROJO}[JITSI] === Programa Terminado por el usuario ===${FIN}"
    exit 0
}

read -p "Ingresa el dominio para Jitsi: " JITSI_HOSTNAME
read -p "Ingresa el nombre de usuario con permisos para crear meetings: " JITSI_ADMIN
read -sp "Ingresa el password para ${JITSI_ADMIN}: " JITSI_PASSWORD
echo

configurar_hostname() {
    echo -e "\n${AMARILLO}[JITSI] === Configurando hostname ===${FIN}"
    sudo hostnamectl set-hostname "${JITSI_HOSTNAME}"
    sudo sed -i "s/127\.0\.1\.1[\t].*/127.0.1.1       ${JITSI_HOSTNAME}/" /etc/hosts
}

instalar_llaves_y_repos() {
    echo -e "\n${AMARILLO}[JITSI] === Instalando llaves y agregando repositorios ===${FIN}"
    
    # Llave y repositorio de Prosody
    sudo curl -sL https://prosody.im/files/prosody-debian-packages.key -o /etc/apt/keyrings/prosody-debian-packages.key
    echo "deb [signed-by=/etc/apt/keyrings/prosody-debian-packages.key] http://packages.prosody.im/debian $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/prosody.list
    
    # Llave y repositorio de Jitsi
    curl -sL https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
    echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi.list > /dev/null
}

instalar_jitsi() {
    echo -e "\n${AMARILLO}[JITSI] === Actualizando repositorios e instalando Jitsi Meet ===${FIN}"
    sudo apt update && sudo apt install -y jitsi-meet
}

configurar_autenticacion() {
    echo -e "\n${AMARILLO}[JITSI] === Configurando autenticación ===${FIN}"
    sudo sed -i "s/jitsi-anonymous/internal_hashed/" /etc/prosody/conf.avail/"${JITSI_HOSTNAME}".cfg.lua
    
    sudo tee -a /etc/prosody/conf.avail/"${JITSI_HOSTNAME}".cfg.lua > /dev/null <<EOL
    VirtualHost 'guest.$(hostname -f)'
    authentication = 'anonymous'
    c2s_require_encryption = false
EOL

    echo -e "\n${AMARILLO}[JITSI] === Configurando dominio anónimo ===${FIN}"
    sudo sed -i "s/\/\/ anonymousdomain: 'guest\.example\.com'/anonymousdomain: 'guest.${JITSI_HOSTNAME}'/" /etc/jitsi/meet/"${JITSI_HOSTNAME}"-config.js
}

configurar_jicofo() {
    echo -e "\n${AMARILLO}[JITSI] === Configurando Jicofo ===${FIN}"
    sudo tee /etc/jitsi/jicofo/sip-communicator.properties > /dev/null <<EOL
    org.jitsi.jicofo.auth.URL=XMPP:$(hostname -f)
EOL
}

crear_usuario() {
    echo -e "\n${AMARILLO}[JITSI] === Creando usuario local ===${FIN}"
    sudo prosodyctl register "${JITSI_ADMIN}" "${JITSI_HOSTNAME}" "${JITSI_PASSWORD}"
}

reiniciar_servicios() {
    echo -e "\n${AMARILLO}[JITSI] === Reiniciando los servicios ===${FIN}"
    sudo systemctl restart prosody.service jicofo.service jitsi-videobridge2.service
}

# Funciones
configurar_hostname
instalar_llaves_y_repos
instalar_jitsi
configurar_autenticacion
configurar_jicofo
crear_usuario
reiniciar_servicios

echo -e "\n${VERDE}[JITSI] === Instalación completada exitosamente ===${FIN}"
