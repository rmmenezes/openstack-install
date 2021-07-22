#!/bin/bash
set -x #echo on

hostname glance
echo glance > /etc/hostname

# Carregando as variaveis no ambiente
chmod 777 ./variables.sh
./variables.sh

# Arquivo de hosts (DNS)
mv /etc/hosts /etc/hosts.original
eval "echo \"$(cat ./files/hosts.template)\" > /etc/hosts"


mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@glance
NODE_IP_ADDRESS=$ip_vm_glance
NODE_PORT=5672
EOF

chmod 777 ./scripts/debian_update.sh
chmod 777 ./scripts/default.sh
chmod 777 ./scripts/glance.sh

./scripts/debian_update.sh
./scripts/default.sh
./scripts/glance.sh

service rabbit* restart