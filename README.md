# bash_jitsi_meet
Repo con scripts para instalar un servicio jitsi-meet + ldap para validación.

Testeado con Vagrant + qemu + ubuntu_22.04.

---
### Descripción

La idea del proyecto es automatizar vía bash scripting la instalación/configuración de [jitsi-meet](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-quickstart/) + [ldap](https://ubuntu.com/server/docs/install-and-configure-ldap) para pruebas de laboratorio, el repo cuenta con 2 scripts:

1. jitsi_installer.sh
2. jitsi_ldap_installer.sh

### Dependencias

* [Vagrant](https://developer.hashicorp.com/vagrant/install) (opcional)

### Uso
```
git clone https://github.com/pgraffigna/bash_jitsi_meet.git
cd bash_jitsi_meet
chmod +x *.sh 
./jitsi_installer.sh 
./jitsi_ldap_installer.sh
```
### Extras
* Archivo de configuración (Vagrantfile) para desplegar una VM descartable con ubuntu-22.04 con libvirt como hipervisor.

### Uso Vagrant (opcional)
```
vagrant up
vagrant ssh
```

