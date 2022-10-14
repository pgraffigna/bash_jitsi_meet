#!/bin/bash
# script para instalar ldap + conexión a ldap

#colores
VERDE="\e[0;32m\033[1m"
ROJO="\e[0;31m\033[1m"
AMARILLO="\e[0;33m\033[1m"
FIN="\033[0m\e[0m"

#Ctrl-C
trap ctrl_c INT
function ctrl_c(){
        echo -e "\n${ROJO}Programa Terminado por el usuario ${FIN}"
        exit 0
}

echo -e "${AMARILLO}Instalando dependencias para ldap ${FIN}"
sudo apt-get install -y sasl2-bin libsasl2-modules-ldap lua-cyrussasl prosody-modules

echo -e "${AMARILLO}Instalando modulo cyrus ${FIN}"
sudo prosodyctl install --server=https://modules.prosody.im/rocks/ mod_auth_cyrus

echo -e "\n${AMARILLO}Configurando ldap ${FIN}"
cat << 'EOF' | sudo tee /etc/saslauthd.conf > /dev/null
ldap_servers: ldap://192.168.121.152
ldap_bind_dn: cn=admin,dc=testing
ldap_bind_pw: password
ldap_auth_method: bind
ldap_search_base: ou=usuario,dc=testing
ldap_filter: (&(uid=%u)(objectClass=*)(title=jitsi)) 
ldap_version: 3
EOF

echo -e "\n${AMARILLO}configurar saslauthd para que inicie en boot + que use ldap para validar ${FIN}"
sudo sed -i -e "s/START=.*/START=yes/" -e "s/MECHANISMS=.*/MECHANISMS=\"ldap\"/" /etc/default/saslauthd

echo -e "\n${VERDE}reiniciando demonio sasl ${FIN}"
sudo service saslauthd restart 

echo -e "\n${AMARILLO}configurando Cyrus SASL ${FIN}"
sudo mkdir /etc/sasl 

cat << 'EOF' |sudo tee /etc/sasl/prosody.conf > /dev/null
pwcheck_method: saslauthd
mech_list: PLAIN
EOF

echo -e "\n${AMARILLO}configurando prosody ${FIN}"
sudo sed -i -E -e "/^ *VirtualHost \"$(hostname -f)\"/,/^ *VirtualHost/ {s/authentication ?=.*$/authentication = \"cyrus\"/}" /etc/prosody/conf.avail/$(hostname -f).cfg.lua

echo -e "\n${AMARILLO}agregando al usuario PROSODY al grupo SASL ${FIN}"
sudo usermod -a -G sasl prosody

echo -e "\n${VERDE}reiniciando el servicio prosody ${FIN}"
sudo service prosody restart
