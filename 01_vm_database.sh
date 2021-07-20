#!/bin/bash
set -x #echo on

hostname database
echo database > /etc/hostname

mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@database
NODE_IP_ADDRESS=192.168.90.186  
NODE_PORT=5672
EOF

chmod 777 ./scripts/debian_update.sh
chmod 777 ./scripts/default.sh
chmod 777 ./scripts/database.sh

scripts/debian_update.sh
scripts/default.sh
scripts/database.sh


service rabbit* restart