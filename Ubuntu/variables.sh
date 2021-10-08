#!/bin/bash

cat > ~/.bashrc << EOF
## Edit here ##
export ip_vm_database="192.168.122.181"
export ip_vm_keystone="192.168.122.181"
export ip_vm_glance="192.168.122.181"
export ip_vm_horizon="192.168.122.181"
export ip_vm_placement="192.168.122.181"
export ip_vm_nova_controller="192.168.122.181"
export ip_vm_neutron_controller="192.168.122.181"
export ip_vm_cinder="192.168.122.181"

export ip_vm_nova_compute="192.168.122.43"
export ip_vm_neutron_compute="192.168.122.43"
## Edit here ##

## Dont edit here ##
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://keystone:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_TENANT_NAME=admin
## Dont edit here ##
EOF

source ~/.bashrc