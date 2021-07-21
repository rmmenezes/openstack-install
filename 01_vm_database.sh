#!/bin/bash
set -x #echo on

hostname database
echo database > /etc/hostname

# Carregando as variaveis no ambiente
chmod 777 ./variables.sh
./variables.sh

mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@database
NODE_IP_ADDRESS=$ip_vm_database
NODE_PORT=5672
EOF

chmod 777 ./scripts/debian_update.sh
chmod 777 ./scripts/default.sh
chmod 777 ./scripts/database.sh

./scripts/debian_update.sh
./scripts/default.sh
./scripts/database.sh

service rabbit* restart