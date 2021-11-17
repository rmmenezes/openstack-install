#!/bin/bash
set -x #echo on

# Carregando as variaveis no ambiente
chmod 777 ../variables.sh
../variables.sh
source ~/.bashrc


mysql --user="root" --password="password" --execute="CREATE DATABASE IF NOT EXISTS placement;"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'database' IDENTIFIED BY 'PLACEMENT_DBPASS';"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'PLACEMENT_DBPASS';"


openstack user create --domain default --password PLACEMENT_PASS placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement


openstack endpoint create --region RegionOne placement public http://placement:8778
openstack endpoint create --region RegionOne placement internal http://placement:8778
openstack endpoint create --region RegionOne placement admin http://placement:8778

apt install placement-api -y
apt install python3-pip -y


mv /etc/placement/placement.conf /etc/placement/placement.conf.original
eval "echo \"$(cat ./files/placement/placement.conf.template)\" > /etc/placement/placement.conf"
chgrp placement /etc/placement/placement.conf

su -s /bin/sh -c "placement-manage db sync" placement
service apache2 restart
apt install python3-osc-placement -y

openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name

echo "FIM !"