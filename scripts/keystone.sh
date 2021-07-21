#!/bin/bash
set -x #echo on

mysql --user="openstack" --password="password" -h database --execute="CREATE DATABASE IF NOT EXISTS keystone;"
mysql --user="openstack" --password="password" -h database --execute="GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'database' IDENTIFIED BY 'KEYSTONE_DBPASS';"
mysql --user="openstack" --password="password" -h database --execute="GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';"

apt install keystone -y

mv /etc/keystone/keystone.conf /etc/keystone/keystone.conf.original
cp ./files/keystone/keystone.conf /etc/keystone/keystone.conf 
chgrp keystone /etc/keystone/keystone.conf 

sudo su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone


keystone-manage bootstrap --bootstrap-password ADMIN_PASS --bootstrap-admin-url http://keystone:5000/v3/ --bootstrap-internal-url http://keystone:5000/v3/ --bootstrap-public-url http://keystone:5000/v3/ --bootstrap-region-id RegionOne
  
service apache2 restart

openstack domain create --description "An Example Domain" example
openstack project create --domain default --description "Service Project" service
openstack project create --domain default --description "Demo Project" myproject
openstack user create --domain default --password password myuser
openstack role create myrole
openstack role add --project myproject --user myuser myrole

echo "FIM !"