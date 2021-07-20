#!/bin/bash
set -x #echo on

hostname nova
echo nova > /etc/hostname

mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@nova
NODE_IP_ADDRESS=192.168.90.249
NODE_PORT=5672
EOF

chmod 777 ./scripts/debian_update.sh
chmod 777 ./scripts/default.sh
chmod 777 ./scripts/nova.sh

scripts/debian_update.sh
scripts/default.sh
scripts/nova.sh

service rabbit* restart