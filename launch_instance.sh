#!/bin/bash
##############################################################################
# File Name:   launch_instance.sh
# Version:     2.6
# Date:        2017-05-08
# Author:      Maxwell Li
# Email:       liyuenan93@qq.com
# Web:         maxwelli.com
# Description: Launch some instances
# Note:        Update to openstack client
##############################################################################
# Version:     2.5
# Date:        2017-03-23
# Note:        Add key for instances
# Version:     2.4
# Date:        2017-02-20
# Note:        Add dns name server for subnet
# Version:     2.3
# Date:        2017-02-17
# Note:        The number of instance need to input
# Version:     2.2
# Date:        2017-02-16
# Note:        Use test flavor rather than nano
# Version:     2.1
# Date:        2017-02-12
# Note:        Change test image name and delete flavor id
# Version:     2.0
# Date:        2017-02-08
# Note:        First verison
##############################################################################

# Run this script in a controller node.
if [ ! -z "$1" ]; then
    demo_number=$1
else
    echo "Please input the number of instance you need launch."
    exit 1
fi
set -xe

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

# List the image
openstack image list

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

# List the net and subnet
openstack network list
openstack subnet list

# Create the router, add the demo-net network subnet and set a gateway on the ext-net network on the router:
if [[ ! $(openstack router list| grep demo-router) ]]; then
    openstack router create demo-router
    neutron router-interface-add demo-router demo-subnet
    neutron router-gateway-set demo-router ext-net
fi

# List the router
openstack router list

# Generate and add a key pair
if [[ ! $(openstack keypair list | grep mykey) ]]; then
    openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey
fi

# Launch the instance:
for i in $(seq 1 $demo_number)
do
    if [[ ! $(openstack server list | grep "demo$i") ]]; then
        openstack server create\
            --flavor m1.nano \
            --image $(openstack image list | grep cirros | awk '{print $2}') \
            --nic net-id=$(neutron net-list | grep demo-net | awk '{print $2}') \
            --security-group default \
            --key-name mykey \
            "demo$i"
        sleep 10

        # Create a floating IP address and associate it with the instance:
        floating_ip=$(openstack floating ip create ext-net \
                    | grep floating_ip_address | awk '{print $4}')
        openstack server add floating ip "demo$i" $floating_ip
    fi
done

set +xe

# List the instance
openstack server list

# Login the instance
echo "+--------------------------------------+"
echo "| Login the instance                   |"
echo "+--------------------------------------+"
for i in $(seq 1 $demo_number)
do
    floating_ip=$(openstack server list | grep "demo$i" | awk '{print $9}')
    echo "| demo$i: ssh cirros@$floating_ip    |"
done
echo "| NOTE: DEFAULT PASSWORD is cubswin:)  |"
echo "+--------------------------------------+"
