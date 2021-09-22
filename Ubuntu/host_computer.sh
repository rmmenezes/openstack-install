#!/bin/bash
set -x #echo on

sudo add-apt-repository cloud-archive:wallaby -y
sudo apt-get update -y
sudo apt-get upgrade -y

hostname compute
echo compute > /etc/hostname

# Carregando as variaveis no ambiente
chmod 777 ./variables.sh
./variables.sh
source ~/.bashrc

# Arquivo de hosts (DNS)
cp /etc/hosts /etc/hosts.original
eval "echo \"$(cat ./files/hosts.template)\" > /etc/hosts"

chmod 777 ./scripts/ubuntu_update.sh
chmod 777 ./scripts/nova_compute.sh
chmod 777 ./scripts/neutron_compute.sh

./scripts/ubuntu_update.sh
./scripts/nova_compute.sh
./scripts/neutron_compute.sh