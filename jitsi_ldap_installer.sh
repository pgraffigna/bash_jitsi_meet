#!/bin/bash
# Script para configurar conexion ldap + jitsi
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
    echo -e "\n${ROJO}[LDAP] === Programa Terminado por el usuario ===${FIN}"
    exit 0
}

configurar_dependencias(){
    echo -e "${AMARILLO}[LDAP] === Instalando dependencias para ldap ===${FIN}"
    sudo apt-get install -y sasl2-bin libsasl2-modules-ldap lua-cyrussasl

    echo -e "${AMARILLO}[LDAP] === Instalando modulo cyrus ===${FIN}"
    sudo prosodyctl install --server=https://modules.prosody.im/rocks/ mod_auth_cyrus
}

configurar_ldap(){
    echo -e "\n${AMARILLO}[LDAP] === Configurando ldap ===${FIN}"
    cat << 'EOL' | sudo tee /etc/saslauthd.conf > /dev/null
    ldap_servers: ldap://192.168.121.217
    ldap_scope: sub
    ldap_sasl_mech: plain
    ldap_bind_dn: cn=admin,dc=home,dc=lab
    ldap_bind_pw: password
    ldap_auth_method: bind
    ldap_search_base: ou=USUARIOS,dc=home,dc=lab
    ldap_filter: (&(uid=%U)(objectclass=*)(title=jitsi))
    ldap_version: 3
    ldap_use_sasl: no
    ldap_start_tls: no
EOL
}

configurar_sasl(){
    echo -e "\n${AMARILLO}[LDAP] === Configurar saslauthd para que inicie en boot + que use ldap para validar ===${FIN}"
    sudo sed -i -e "s/START=.*/START=yes/" -e "s/MECHANISMS=.*/MECHANISMS=\"ldap\"/" -e "s/^OPTIONS=.*/OPTIONS=\"-r -c -m \/var\/run\/saslauthd\"/" /etc/default/saslauthd

    echo -e "\n${VERDE}=== Reiniciando demonio sasl ===${FIN}"
    sudo service saslauthd restart 

    echo -e "\n${AMARILLO}[LDAP] === Configurando Cyrus SASL ===${FIN}"
    sudo mkdir /etc/sasl

    cat << 'EOL' |sudo tee /etc/sasl/prosody.conf > /dev/null
        pwcheck_method: saslauthd
        mech_list: PLAIN
EOL
}

configurar_prosody(){
    echo -e "\n${AMARILLO}[LDAP] === Configurando prosody ===${FIN}"
    sudo sed -i -E -e "/^ *VirtualHost \"$(hostname -f)\"/,/^ *VirtualHost/ {s/authentication ?=.*$/authentication = \"cyrus\"/}" /etc/prosody/conf.avail/$(hostname -f).cfg.lua

    echo -e "\n${AMARILLO}[LDAP] === Agregando al usuario PROSODY al grupo SASL ===${FIN}"
    sudo usermod -a -G sasl prosody

    echo -e "\n${VERDE}[LDAP] === Reiniciando el servicio prosody ===${FIN}"
    sudo service prosody restart
}

#Funciones
configurar_dependencias
configurar_ldap
configurar_sasl
configurar_prosody

echo -e "\n${VERDE}[JITSI] === Instalación completada exitosamente ===${FIN}"

## puertos para jitsi
# ufw allow 80,443,5349/tcp
# ufw allow 3478,10000/udp

