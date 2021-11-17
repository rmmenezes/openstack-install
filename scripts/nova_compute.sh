#!/bin/bash
set -x #echo on

# Carregando as variaveis no ambiente
chmod 777 ../variables.sh
../variables.sh
source ~/.bashrc


apt install nova-compute -y

mv /etc/nova/nova.conf /etc/nova/nova.conf.original
eval "echo \"$(cat ./files/nova_compute/nova.conf.template)\" > /etc/nova/nova.conf"
chgrp nova /etc/nova/nova.conf

mv /etc/nova/nova-compute.conf /etc/nova/nova-compute.conf.original
eval "echo \"$(cat ./files/nova_compute/nova-compute.conf.template)\" > /etc/nova/nova-compute.conf"
chgrp nova /etc/nova/nova-compute.conf

echo "FIM