#!/bin/bash
set -x #echo on

hostname nova
echo nova > /etc/hostname

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
NODENAME=rabbit@nova
NODE_IP_ADDRESS=$ip_vm_nova
NODE_PORT=5672
EOF

chmod 777 ./scripts/debian_update.sh
chmod 777 ./scripts/default.sh
chmod 777 ./scripts/nova.sh

./scripts/debian_update.sh
./scripts/default.sh
./scripts/nova.sh

service rabbit* restart