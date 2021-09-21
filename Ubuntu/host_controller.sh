#!/bin/bash
set -x #echo on

hostname controller
echo controller > /etc/hostname

# Carregando as variaveis no ambiente
chmod 777 ./variables.sh
./variables.sh
source ~/.bashrc

# Arquivo de hosts (DNS)
cp /etc/hosts /etc/hosts.original
eval "echo \"$(cat ./files/hosts.template)\" > /etc/hosts"

chmod 777 ./scripts/ubuntu_update.sh
chmod 777 ./scripts/database.sh
chmod 777 ./scripts/default.sh
chmod 777 ./scripts/keystone.sh
chmod 777 ./scripts/glance.sh
chmod 777 ./scripts/horizon.sh

./scripts/debian_update.sh
./scripts/database.sh
./scripts/default.sh
./scripts/keystone.sh
./scripts/glance.sh
./scripts/horizon.sh
