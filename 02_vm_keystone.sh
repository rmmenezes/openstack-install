#!/bin/bash
set -x #echo on

hostname keystone
echo keystone > /etc/hostname

# Carregando as variaveis no ambiente
chmod 777 ./variables.sh
./variables.sh
source ~/.bashrc


# Arquivo de hosts (DNS)
cp /etc/hosts /etc/hosts.original
eval "echo \"$(cat ./files/hosts.template)\" > /etc/hosts"

mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@keystone
NODE_IP_ADDRESS=$ip_vm_keystone
NODE_PORT=5672
EOF



chmod 777 ./scripts/debian_update.sh
chmod 777 ./scripts/default.sh
chmod 777 ./scripts/keystone.sh

./scripts/debian_update.sh
./scripts/default.sh
./scripts/keystone.sh

service rabbit* restart