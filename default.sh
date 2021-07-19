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


