#!/bin/bash
set -x #echo on

mysql --user="root" --password="password" --execute="CREATE DATABASE IF NOT EXISTS glance;"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'database' IDENTIFIED BY 'GLANCE_DBPASS';"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';"
	
sudo DEBIAN_FRONTEND=noninteractive apt install glance -y

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

echo "FIM !"