#!/bin/bash
set -x #echo on

hostname keystone
echo keystone > /etc/hostname

mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@keystone
NODE_IP_ADDRESS=192.168.90.45
NODE_PORT=5672
EOF



chmod 777 scripts/debian_update.sh
chmod 777 scripts/default.sh
chmod 777 scripts/keystone.sh

scripts/debian_update.sh
scripts/default.sh
scripts/keystone.sh

service rabbit* restart