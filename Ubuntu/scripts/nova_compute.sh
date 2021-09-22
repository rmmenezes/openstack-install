#!/bin/bash
set -x #echo on

apt install nova-compute -y

mv /etc/nova/nova.conf /etc/nova/nova.conf.original
eval "echo \"$(cat ./files/nova_compute/nova.conf.template)\" > /etc/nova/nova.conf"
chgrp nova /etc/nova/nova.conf

echo "FIM !"