#!/bin/bash
set -x #echo on

hostname neutron
echo neutron > /etc/hostname

# Carregando as variaveis no ambiente
chmod 777 ./variables.sh
./variables.sh


mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@neutron
NODE_IP_ADDRESS=$ip_vm_neutron
NODE_PORT=5672
EOF

chmod 777 ./scripts/debian_update.sh
chmod 777 ./scripts/default.sh
chmod 777 ./scripts/neutron.sh

./scripts/debian_update.sh
./scripts/default.sh
./scripts/neutron.sh

service rabbit* restart