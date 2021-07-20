#!/bin/bash
set -x #echo on
# add-apt-repository cloud-archive:wallaby -y (PARA UBUNTU)
apt-get update -y 
apt-get upgrade -y

# Arquivo de hosts (DNS)
mv /etc/hosts /etc/hosts.original
cp ./files/hosts /etc/hosts 
chgrp root /etc/hosts 

# apt install python3-openstackclient -y (CLIENTE PARA UBUNTU!)
apt install python3-pip -y
pip install python-openstackclient

apt install rabbitmq-server -y
rabbitmqctl add_user openstack RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"

apt install memcached python3-memcache -y
service memcached restart

apt install etcd -y
cat > /etc/default/etcd << EOF
ETCD_NAME="controller"
ETCD_DATA_DIR="/var/lib/etcd"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-01"
ETCD_INITIAL_CLUSTER="controller=http://keystone:2380"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://keystone:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://keystone:2379"
ETCD_LISTEN_PEER_URLS="http://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="http://keystone:2379"
EOF

systemctl enable etcd
systemctl restart etcd

apt install mariadb-server python3-pymysql -y
touch /etc/mysql/mariadb.conf.d/99-openstack.cnf
cat > /etc/mysql/mariadb.conf.d/99-openstack.cnf << EOF
[mysqld]
bind-address = 0.0.0.0

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
EOF

service mysql restart
sudo systemctl restart mysql
sudo systemctl restart mariadb
service mysql restart

cat > /etc/sysctl.conf << EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
EOF
sysctl -p /etc/sysctl.conf

echo "FIM !"

# ANTES, CIRAR UM NOVO DISCO E ADICIONAR A VM NO VIRT_MANANGER!!!!
mysql --user="openstack" -h ip_database --password="password" --execute="CREATE DATABASE IF NOT EXISTS cinder;"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'ip_database' IDENTIFIED BY 'CINDER_DBPASS';"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'CINDER_DBPASS';"
	
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://keystone:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_TENANT_NAME=admin

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

apt install cinder-api cinder-scheduler -y

mv /etc/cinder/cinder.conf /etc/cinder/cinder.conf.original
cp ./files/cinder/cinder.conf /etc/cinder/cinder.conf
chgrp cinder /etc/cinder/cinder.conf

su -s /bin/sh -c "cinder-manage db sync" cinder
systemctl restart cinder-scheduler
openstack volume service list

apt install lvm2 thin-provisioning-tools -y

#monta o disco
pvcreate /dev/vdb
vgcreate cinder-volumes /dev/vdb

sed -i '/devices {$/a filter = [ "a/vdb/", "r/.*/"]' /etc/lvm/lvm.conf

apt install cinder-volume -y
systemctl restart cinder-volume

echo "FIM !"