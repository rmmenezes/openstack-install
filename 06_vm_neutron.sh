#!/bin/bash
set -x #echo on

hostname neutron
echo neutron > /etc/hostname

mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@neutron
NODE_IP_ADDRESS=192.168.122.156
NODE_PORT=5672
EOF

chmod 777 ./scripts/debian_update.sh
chmod 777 ./scripts/default.sh
chmod 777 ./scripts/neutron.sh

./scripts/debian_update.sh
./scripts/default.sh
./scripts/neutron.sh

service rabbit* restart