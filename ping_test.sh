#!/bin/bash
##############################################################################
# File Name:   ping_test.sh
# Revision:    2.0
# Date:        2017-02-08
# Author:      Yuenan Li
# Email:       liyuenan93@icloud.com
# Blog:        liyuenan.com
# Description: Test launch instance on openstack
##############################################################################

# Run this script in a controller node.
set -ex

# source the admin credentials to gain access to admin-only CLI commands:
source /opt/admin-openrc.sh

# Download the source image:
if [[ ! -e cirros-0.3.4-x86_64-disk.img ]]; then
    wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
fi

# Upload the image to the Image service using the QCOW2 disk format, bare container format:
if [[ ! $(glance image-list | grep cirros) ]]; then
    glance image-create --name "cirros" \
        --file cirros-0.3.4-x86_64-disk.img  \
        --disk-format qcow2 --container-format bare
fi

# Add rules to the default security group:
if [[ ! $(nova secgroup-list-rules default | grep icmp) ]]; then
    nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
fi
if [[ ! $(nova secgroup-list-rules default | grep tcp) ]]; then
    nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
fi

# Create the net and a subnet on the network:
if [[ ! $(neutron net-list | grep demo-net) ]]; then
    neutron net-create demo-net
fi
if [[ ! $(neutron subnet-list | grep demo-subnet) ]]; then
    neutron subnet-create demo-net 10.10.10.0/24 --name demo-subnet --gateway 10.10.10.1
fi

# Create the router, add the demo-net network subnet and set a gateway on the ext-net network on the router:
if [[ ! $(neutron router-list | grep demo-router) ]]; then
    neutron router-create demo-router
    neutron router-interface-add demo-router demo-subnet
    neutron router-gateway-set demo-router ext-net
fi

# Create m1.test flavor
if [[ ! $(openstack flavor list | grep m1.test) ]]; then
    openstack flavor create --id 100 --vcpus 1 --ram 256 --disk 1 m1.test
fi

# Generate and add a key pair
if [[ ! $(openstack keypair list | grep testkey) ]]; then
    openstack keypair create --public-key ~/.ssh/id_rsa.pub testkey
fi

# Launch the instance:
if [[ ! $(nova list | grep "ping1") ]]; then
    nova boot --flavor m1.test --image cirros \
        --nic net-id=$(neutron net-list | grep demo-net | awk '{print $2}') \
        --security-group default --key-name testkey ping1
    sleep 10
    # Create a floating IP address and associate it with the instance:
    floating_ip1=$(neutron floatingip-create ext-net \
                | grep floating_ip_address | awk '{print $4}')
    nova floating-ip-associate ping1 $floating_ip1
fi

if [[ ! $(nova list | grep "ping2") ]]; then
    nova boot --flavor m1.test --image cirros \
        --nic net-id=$(neutron net-list | grep demo-net | awk '{print $2}') \
        --security-group default --key-name testkey ping2
    sleep 10
    # Create a floating IP address and associate it with the instance:
    floating_ip2=$(neutron floatingip-create ext-net \
                | grep floating_ip_address | awk '{print $4}')
    nova floating-ip-associate ping2 $floating_ip2
fi

# Ping Test
ssh cirros@$floating_ip1 ping -c 4 $floating_ip2
ssh cirros@$floating_ip2 ping -c 4 $floating_ip1

# Clean the openstack
#openstack keypair delete testkey
#nova delete ping1
#nova delete ping2

set +ex

echo "===== Test Pass! ====="
