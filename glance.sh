#!/bin/bash
set -x #echo on

mysql --user="openstack" -h ip_database --password="password" --execute="CREATE DATABASE IF NOT EXISTS glance;"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'ip_database' IDENTIFIED BY 'GLANCE_DBPASS';"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';"
	
apt install glance -y

export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://keystone:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_TENANT_NAME=admin

mv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.original
cp ./files/glance/glance-api.conf /etc/glance/glance-api.conf
chgrp glance /etc/glance/glance-api.conf

su -s /bin/sh -c "glance-manage db_sync" glance
service glance-api restart

openstack user create --domain default --password GLANCE_PASS glance
openstack role add --project service --user glance admin
openstack service create --name glance --description "OpenStack Image service" image
openstack endpoint create --region RegionOne image public http://glance:9292
openstack endpoint create --region RegionOne image internal http://glance:9292
openstack endpoint create --region RegionOne image admin http://glance:9292

wget http://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
glance image-create --name "cirros" --file cirros-0.4.0-x86_64-disk.img --disk-format qcow2 --container-format bare --visibility=public
