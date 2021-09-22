#!/bin/bash
set -x #echo on

apt install neutron-linuxbridge-agent -y


mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.original
cp ./files/neutron_compute/neutron.conf /etc/neutron/neutron.conf
chgrp neutron /etc/neutron/neutron.conf

mv /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.original
cp ./files/neutron_compute/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
chgrp neutron /etc/neutron/plugins/ml2/linuxbridge_agent.ini

sudo systemctl restart nova-compute
sudo systemctl restart neutron-linuxbridge-agent

echo "FIM !"