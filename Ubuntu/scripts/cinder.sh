#!/bin/bash
set -x #echo on

# ANTES, CIRAR UM NOVO DISCO E ADICIONAR A VM NO VIRT_MANANGER!!!!
mysql --user="root" --password="password" --execute="CREATE DATABASE IF NOT EXISTS cinder;"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'database' IDENTIFIED BY 'CINDER_DBPASS';"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'CINDER_DBPASS';"
	
openstack user create --domain default --password CINDER_PASS cinder
openstack role add --project service --user cinder admin

openstack service create --name cinderv2 --description "OpenStack Block Storage" volumev2
openstack service create --name cinderv3 --description "OpenStack Block Storage" volumev3

openstack endpoint create --region RegionOne volumev2 public http://cinder:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 internal http://cinder:8776/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev2 admin http://cinder:8776/v2/%\(tenant_id\)s

openstack endpoint create --region RegionOne volumev3 public http://cinder:8776/v3/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev3 internal http://cinder:8776/v3/%\(tenant_id\)s
openstack endpoint create --region RegionOne volumev3 admin http://cinder:8776/v3/%\(tenant_id\)s

sudo DEBIAN_FRONTEND=noninteractive apt install cinder-api cinder-scheduler -y

mv /etc/cinder/cinder.conf /etc/cinder/cinder.conf.original
cp ./files/cinder/cinder.conf /etc/cinder/cinder.conf
chgrp cinder /etc/cinder/cinder.conf

su -s /bin/sh -c "cinder-manage db sync" cinder
systemctl restart cinder-scheduler
openstack volume service list

sudo DEBIAN_FRONTEND=noninteractive apt install lvm2 thin-provisioning-tools -y

#monta o disco
pvcreate /dev/vdb
vgcreate cinder-volumes /dev/vdb

sed -i '/devices {$/a filter = [ "a/vdb/", "r/.*/"]' /etc/lvm/lvm.conf

sudo DEBIAN_FRONTEND=noninteractive apt install cinder-volume -y
systemctl restart cinder-volume

echo "FIM !"