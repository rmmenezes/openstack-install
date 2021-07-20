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

hostname neutron
echo neutron > /etc/hostname

mkdir /etc/rabbitmq/
touch /etc/rabbitmq/rabbitmq-env.conf

cat > /etc/rabbitmq/rabbitmq-env.conf << EOF
NODENAME=rabbit@neutron
NODE_IP_ADDRESS=192.168.90.103
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


mysql --user="openstack" -h ip_database --password="password" --execute="CREATE DATABASE neutron;"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'ip_database' IDENTIFIED BY 'NEUTRON_DBPASS';"
mysql --user="openstack" -h ip_database --password="password" --execute="GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'NEUTRON_DBPASS';"

export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://keystone:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_TENANT_NAME=admin

openstack user create --domain default --password NEUTRON_PASS neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron --description "OpenStack Networking" network
openstack endpoint create --region RegionOne network public http://neutron:9696
openstack endpoint create --region RegionOne network internal http://neutron:9696
openstack endpoint create --region RegionOne network admin http://neutron:9696


hwclock --hctosys 
apt-get update -y
apt install neutron-server neutron-plugin-ml2 neutron-linuxbridge-agent neutron-dhcp-agent neutron-metadata-agent neutron-linuxbridge-agent -y

mv /etc/neutron/neutron.conf /etc/neutron/neutron.conf.original
cp ./files/neutron/neutron.conf /etc/neutron/neutron.conf
chgrp neutron /etc/neutron/neutron.conf

mv /etc/neutron/plugins/ml2/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini.original
cp ./files/neutron/ml2_conf.ini /etc/neutron/plugins/ml2/ml2_conf.ini
chgrp neutron /etc/neutron/plugins/ml2/ml2_conf.ini


mv /etc/neutron/plugins/ml2/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini.original
cp ./files/neutron/linuxbridge_agent.ini /etc/neutron/plugins/ml2/linuxbridge_agent.ini
chgrp neutron /etc/neutron/plugins/ml2/linuxbridge_agent.ini


mv /etc/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini.original
cp ./files/neutron/dhcp_agent.ini /etc/neutron/dhcp_agent.ini
chgrp neutron /etc/neutron/dhcp_agent.ini

mv /etc/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini.original
cp ./files/neutron/metadata_agent.ini /etc/neutron/metadata_agent.ini
chgrp neutron /etc/neutron/metadata_agent.ini

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron

service nova-api restart

service neutron-server restart
service neutron-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

service neutron-l3-agent restart

service nova-compute restart
service neutron-linuxbridge-agent restart

openstack extension list --network
openstack network agent list

echo "FIM !"