#!/bin/bash
set -x #echo on

# Carregando as variaveis no ambiente
chmod 777 ../variables.sh
../variables.sh
source ~/.bashrc


sudo DEBIAN_FRONTEND=noninteractive apt install openstack-dashboard -y

mv /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.original
cp ./files/horizon/local_settings.py /etc/openstack-dashboard/local_settings.py 

systemctl reload apache2.service

echo "FIM !"