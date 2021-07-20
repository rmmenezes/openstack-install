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

hostname glance
echo glance > /etc/hostname

mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@glance
NODE_IP_ADDRESS=192.168.90.200 
NODE_PORT=5672
EOF


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

echo "FIM !"