#!/bin/bash
set -x #echo on

hostname horizon
echo horizon > /etc/hostname

mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@horizon
NODE_IP_ADDRESS=192.168.90.17
NODE_PORT=5672
EOF

chmod 777 scripts/debian_update.sh
chmod 777 scripts/default.sh
chmod 777 scripts/horizon.sh

scripts/debian_update.sh
scripts/default.sh
scripts/horizon.sh

service rabbit* restart