#!/bin/bash
set -x #echo on
echo "nova" > /etc/hostname

mysql --user="openstack" -h ip_database --password="password" --execute="CREATE DATABASE IF NOT EXISTS nova_api;"
mysql --user="openstack" -h ip_database --password="password" --execute="CREATE DATABASE IF NOT EXISTS nova;"
mysql --user="openstack" -h ip_database --password="password" --execute="CREATE DATABASE IF NOT EXISTS nova_cell0;"

mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'ip_database' IDENTIFIED BY 'NOVA_DBPASS';"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"

mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'ip_database' IDENTIFIED BY 'NOVA_DBPASS';"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"

mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'ip_database' IDENTIFIED BY 'NOVA_DBPASS';"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';"



export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://keystone:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_TENANT_NAME=admin

openstack user create --domain default --password NOVA_PASS nova
openstack role add --project service --user nova admin
openstack service create --name nova --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne compute public http://nova:8774/v2.1
openstack endpoint create --region RegionOne compute internal http://nova:8774/v2.1
openstack endpoint create --region RegionOne compute admin http://nova:8774/v2.1


mysql --user="openstack" -h ip_database --password="password" --execute="CREATE DATABASE IF NOT EXISTS placement;"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'ip_database' IDENTIFIED BY 'PLACEMENT_DBPASS';"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'PLACEMENT_DBPASS';"


openstack user create --domain default --password PLACEMENT_PASS placement
openstack role add --project service --user placement admin
openstack service create --name placement --description "Placement API" placement


openstack endpoint create --region RegionOne placement public http://nova:8778
openstack endpoint create --region RegionOne placement internal http://nova:8778
openstack endpoint create --region RegionOne placement admin http://nova:8778

apt install nova-compute -y
apt install qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils libguestfs-tools genisoimage virtinst libosinfo-bin -y

# Add usuario Nova no grupo libvirt
adduser nova libvirt
adduser nova libvirt-qemu

# Atualiza os grupos
newgrp libvirt
newgrp libvirt-qemu

mkdir /home/placement
apt install placement-api -y
apt install python3-pip -y

mv /etc/placement/placement.conf /etc/placement/placement.conf.original
cp ./files/nova/placement.conf /etc/placement/placement.conf
chgrp placement /etc/placement/placement.conf

su -s /bin/sh -c "placement-manage db sync" placement
service apache2 restart
# placement-status upgrade check
pip3 install osc-placement
openstack --os-placement-api-version 1.2 resource class list --sort-column name
openstack --os-placement-api-version 1.6 trait list --sort-column name

apt install nova-api nova-conductor nova-novncproxy nova-scheduler -y

mv /etc/nova/nova.conf /etc/nova/nova.conf.original
cp ./files/nova/nova.conf /etc/nova/nova.conf
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

openstack compute service list
openstack catalog list
nova-status upgrade check

apt install nova-compute -y
egrep -c '(vmx|svm)' /proc/cpuinfo

mv /etc/nova/nova-compute.conf /etc/nova/nova-compute.conf.original
cp ./files/nova/nova-compute.conf /etc/nova/nova-compute.conf
chgrp nova /etc/nova/nova-compute.conf

service nova-compute restart

openstack compute service list --service nova-compute
su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

openstack flavor create --public m1.extra_tiny --id auto --ram 256 --disk 0 --vcpus 1 --rxtx-factor 1
