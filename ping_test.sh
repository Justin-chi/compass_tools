#!/bin/bash
##############################################################################
# File Name:   ping_test.sh
# Version:     2.3
# Date:        2017-05-09
# Author:      Maxwell Li
# Email:       liyuenan93@qq.com
# Web:         maxwelli.com
# Description: Test launch instance on openstack
# Note:        Update to openstack client
##############################################################################
# Version:     2.2
# Date:        2017-02-20
# Note:        Add dns name server for subnet
# Version:     2.1
# Date:        2017-02-12
# Note:        Change test image name and delete flavor id
# Version:     2.0
# Date:        2017-02-08
# Note:        First Verison
##############################################################################

# Run this script in a controller node.
set -ex

# source the admin credentials to gain access to admin-only CLI commands:
source /opt/admin-openrc.sh

# Download the source image:
if [[ ! -e cirros-0.3.3-x86_64-disk.img ]]; then
    wget 10.1.0.12/image/cirros-0.3.3-x86_64-disk.img
fi

# Upload the image to the Image service using the QCOW2 disk format, bare container format:
if [[ ! $(openstack image list | grep cirros) ]]; then
    openstack image create --file cirros-0.3.3-x86_64-disk.img  \
        --disk-format qcow2 --container-format bare cirros
fi

# Add rules to the default security group:
if [[ ! $(openstack security group rule list | grep icmp) ]]; then
    openstack security group rule create --proto icmp default
fi
if [[ ! $(openstack security group rule list | grep tcp) ]]; then
    openstack security group rule create --proto tcp --dst-port 22 default
fi

# Create the net and a subnet on the network:
if [[ ! $(openstack network list | grep demo-net) ]]; then
    openstack network create demo-net
fi
if [[ ! $(openstack subnet list | grep demo-subnet) ]]; then
    openstack subnet create --network demo-net --subnet-range 10.10.10.0/24 \
        --gateway 10.10.10.1 --dns-nameserver 8.8.8.8 demo-subnet
fi

# Create the router, add the demo-net network subnet and set a gateway on the ext-net network on the router:
if [[ ! $(openstack router list| grep demo-router) ]]; then
    openstack router create demo-router
    neutron router-interface-add demo-router demo-subnet
    neutron router-gateway-set demo-router ext-net
fi

# Generate and add a key pair
if [[ ! $(openstack keypair list | grep mykey) ]]; then
    openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
fi

# Launch the instance:
if [[ ! $(openstack server list | grep "ping1") ]]; then
    openstack server create\
        --flavor m1.nano \
        --image $(openstack image list | grep cirros | awk '{print $2}') \
        --nic net-id=$(neutron net-list | grep demo-net | awk '{print $2}') \
        --security-group default \
        --key-name mykey \
        ping1
    sleep 10
    # Create a floating IP address and associate it with the instance:
    floating_ip1=$(openstack floating ip create ext-net \
                 | grep floating_ip_address | awk '{print $4}')
    openstack server add floating ip ping1 $floating_ip1
fi

if [[ ! $(openstack server list | grep "ping2") ]]; then
    openstack server create\
        --flavor m1.nano \
        --image $(openstack image list | grep cirros | awk '{print $2}') \
        --nic net-id=$(neutron net-list | grep demo-net | awk '{print $2}') \
        --security-group default \
        --key-name mykey \
        ping2
    sleep 10
    # Create a floating IP address and associate it with the instance:
    floating_ip2=$(openstack floating ip create ext-net \
                 | grep floating_ip_address | awk '{print $4}')
    openstack server add floating ip ping2 $floating_ip2
fi

# Ping Test
ssh cirros@$floating_ip1 ping -c 4 $floating_ip2
sleep 5
ssh cirros@$floating_ip2 ping -c 4 $floating_ip1

set +ex

echo "===== Test Pass! ====="
