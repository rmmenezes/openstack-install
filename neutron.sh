#!/bin/bash
set -x #echo on
echo "neutron" > /etc/hostname


mysql --user="openstack" -h ip_database --password="password" --execute="CREATE DATABASE neutron;"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'ip_database' IDENTIFIED BY 'NEUTRON_DBPASS';"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'NEUTRON_DBPASS';"

export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://keystone:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_TENANT_NAME=admin

openstack user create --domain default --password NEUTRON_PASS neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://neutron:9696
openstack endpoint create --region RegionOne network internal http://neutron:9696
openstack endpoint create --region RegionOne network admin http://neutron:9696


hwclock --hctosys 
apt-get update -y
apt install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-linuxbridge-agent -y

mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.original
cp ./files/neutron/neutron.conf /etc/neutron/neutron.conf
chgrp neutron /etc/neutron/neutron.conf

mv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.original
cp ./files/neutron/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
chgrp neutron /etc/neutron/plugins/ml2/ml2_conf.ini


mv /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.original
cp ./files/neutron/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
chgrp neutron /etc/neutron/plugins/ml2/linuxbridge_agent.ini


mv /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.original
cp ./files/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
chgrp neutron /etc/neutron/dhcp_agent.ini

mv /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.original
cp ./files/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini
chgrp neutron /etc/neutron/metadata_agent.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service nova-api restart

service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

service neutron-l3-agent restart

service nova-compute restart
service neutron-linuxbridge-agent restart

openstack extension list --network
openstack network agent list
