#!/bin/bash
set -x #echo on

apt install openstack-dashboard -y

mv /etc/openstack-dashboard/local_settings.py /etc/openstack-dashboard/local_settings.py.original
cp ./files/horizon/local_settings.py /etc/openstack-dashboard/local_settings.py 

systemctl reload apache2.service