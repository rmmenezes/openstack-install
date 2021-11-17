#!/bin/bash
set -x #echo on

# Carregando as variaveis no ambiente
chmod 777 ../variables.sh
../variables.sh
source ~/.bashrc


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

#----------------------------------------------------
# Make sure that NOBODY can access the server without a password
mysql -e "UPDATE mysql.user SET Password = PASSWORD('password') WHERE User = 'root'"
# Kill the anonymous users
# mysql -e "DROP USER ''@'localhost'"
# Because our hostname varies we'll use some Bash magic here.
# mysql -e "DROP USER ''@'$(hostname)'"
# Kill off the demo database
# sudo mysql -e "DROP DATABASE test"
# Make our changes take effect
mysql -e "FLUSH PRIVILEGES"
# Any subsequent tries to run queries this way will get access denied because lack of usr/pwd param

#Documentação: https://stackoverflow.com/questions/19101243/error-1130-hy000-host-is-not-allowed-to-connect-to-this-mysql-server
# Cria o usuario para ser acessado remotamente
mysql --user="root" --password="password" --execute="CREATE USER 'openstack'@'%' IDENTIFIED BY 'password';"
mysql --user="root" --password="password" --execute="GRANT ALL PRIVILEGES ON *.* TO 'openstack'@'%' WITH GRANT OPTION;"
mysql --user="root" --password="password" --execute="FLUSH PRIVILEGES;"

sed -i '/bind-address            = 127.0.0.1/d' /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i '/\[mysqld\]$/a bind-address            = 0.0.0.0' /etc/mysql/mariadb.conf.d/50-server.cnf

sudo DEBIAN_FRONTEND=noninteractive apt install iptables-persistent -yq
iptables -A INPUT -i enp1s0 -p tcp --destination-port 3306 -j ACCEPT

service mysql restart
sudo systemctl restart mysql
sudo systemctl restart mariadb

echo "FIM !"