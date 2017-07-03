#!/bin/bash
##############################################################################
# File Name:   sr-iov_test.sh
# Version:     1.0
# Date:        2017-07-0333
# Author:      Maxwell Li
# Email:       liyuenan93@qq.com
# Web:         maxwelli.com
# Description: SR-IOV Test
# Note:        First Version
##############################################################################

# Delete network
for i in $(neutron port-list | grep subnet | awk '{print $2}'); do neutron port-delete $i;done
neutron subnet-delete ext-subnet
neutron net-delete ext-net

# Uplod yardstick image
wget http://artifacts.opnfv.org/yardstick/third-party/yardstick-loopback-v1_1.img
openstack image create \
    --file yardstick-loopback-v1_1.img \
    --disk-format qcow2 --container-format bare yardstick

# Create vlan or flat external network
neutron net-create ext-net \
    --provider:network_type flat \
    --provider:physical_network physnet \
    --router:external "True"

neutron subnet-create \
    --name ext-subnet \
    --gateway 192.168.36.1 \
    --dns-nameserver 8.8.8.8 \
    --allocation-pool \
    start=192.168.36.223,end=192.168.36.253 \
    ext-net 192.168.36.0/24

# Create sr-iov port
neutron port-create ext-net --name sr-iov --binding:vnic-type direct

# Create sr-iov zone
openstack aggregate create --zone=sriov sriov
openstack aggregate add host sriov host4
openstack aggregate add host sriov host5

# Create Server
openstack server create \
    --flavor m1.large \
    --image yardstick \
    --security-group default \
    --key-name mykey \
    --nic port-id=$(neutron port-list | grep sr-iov | awk '{print $2}') \
    --availability-zone sriov demo1
