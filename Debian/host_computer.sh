#!/bin/bash
set -x #echo on

hostname compute
echo compute > /etc/hostname

# Carregando as variaveis no ambiente
chmod 777 ./variables.sh
./variables.sh
source ~/.bashrc

# Arquivo de hosts (DNS)
cp /etc/hosts /etc/hosts.original
eval "echo \"$(cat ./files/hosts.template)\" > /etc/hosts"

chmod 777 ./scripts/debian_update.sh
chmod 777 ./scripts/default.sh

./scripts/debian_update.sh
./scripts/default.sh
