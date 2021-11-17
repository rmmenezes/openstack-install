#!/bin/bash
set -x #echo on

# Carregando as variaveis no ambiente
chmod 777 ../variables.sh
../variables.sh
source ~/.bashrc


mysql --user="root" --password="password" --execute="CREATE DATABASE IF NOT EXISTS nova_api;"
mysql --user="root" --password="password" --execute="CREATE DATABASE IF NOT EXISTS nova;"
mysql --user="root" --password="password" --execute="CREATE DATABASE IF NOT EXISTS nova_cell0;"

mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'database' IDENTIFIED BY 'NOVA_DBPASS';"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"

mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'database' IDENTIFIED BY 'NOVA_DBPASS';"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"

mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'database' IDENTIFIED BY 'NOVA_DBPASS';"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"

openstack user create --domain default --password NOVA_PASS nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://nova_controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://nova_controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://nova_controller:8774/v2.1

apt install nova-api nova-conductor nova-novncproxy nova-scheduler -y

mv /etc/nova/nova.conf /etc/nova/nova.conf.original
eval "echo \"$(cat ./files/nova_controller/nova.conf.template)\" > /etc/nova/nova.conf"
chgrp nova /etc/nova/nova.conf

su -s /bin/sh -c "nova-manage api_db sync" nova
su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova
su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova
su -s /bin/sh -c "nova-manage db sync" nova

su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

service nova-api restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

echo "FIM !"