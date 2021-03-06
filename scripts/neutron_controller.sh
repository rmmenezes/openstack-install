#!/bin/bash
set -x #echo on

# Carregando as variaveis no ambiente
chmod 777 ../variables.sh
../variables.sh
source ~/.bashrc


mysql --user="root" --password="password" --execute="CREATE DATABASE neutron;"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'database' IDENTIFIED BY 'NEUTRON_DBPASS';"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'NEUTRON_DBPASS';"

openstack user create --domain default --password NEUTRON_PASS neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://neutron_controller:9696
openstack endpoint create --region RegionOne network internal http://neutron_controller:9696
openstack endpoint create --region RegionOne network admin http://neutron_controller:9696

apt install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent -y

mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.original
cp ./files/neutron_controller/neutron.conf /etc/neutron/neutron.conf
chgrp neutron /etc/neutron/neutron.conf

mv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.original
cp ./files/neutron_controller/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
chgrp neutron /etc/neutron/plugins/ml2/ml2_conf.ini


mv /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.original
cp ./files/neutron_controller/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
chgrp neutron /etc/neutron/plugins/ml2/linuxbridge_agent.ini


mv /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.original
cp ./files/neutron_controller/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
chgrp neutron /etc/neutron/dhcp_agent.ini

mv /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.original
eval "echo \"$(cat ./files/neutron_controller/metadata_agent.ini.template)\" > /etc/neutron/metadata_agent.ini"
chgrp neutron /etc/neutron/metadata_agent.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service nova-api restart

service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

openstack extension list --network
openstack network agent list

echo "FIM !"