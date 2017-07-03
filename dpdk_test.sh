#!/bin/bash
##############################################################################
# File Name:   dpdk_test.sh
# Version:     1.0
# Date:        2017-07-0333
# Author:      Maxwell Li
# Email:       liyuenan93@qq.com
# Web:         maxwelli.com
# Description: dpdk Test
# Note:        First Version
##############################################################################

# Create 2M hugepage flavor
openstack flavor create m1.tiny_huge --ram 512 --disk 1 --vcpus 1
openstack flavor set \
    --property hw:mem_page_size=large \
    --property hw:cpu_policy=dedicated \
    --property hw:cpu_thread_policy=require \
    --property hw:numa_mempolicy=preferred \
    --property hw:numa_nodes=1 \
    --property hw:numa_cpus.0=0 \
    --property hw:numa_mem.0=512 \
    m1.tiny_huge

# Create 1G hugepage flavor
openstack flavor create m1.large_huge --ram 8192 --disk 80 --vcpus 4
openstack flavor set \
    --property hw:mem_page_size=large \
    --property hw:cpu_policy=dedicated \
    --property hw:cpu_thread_policy=require \
    --property hw:numa_mempolicy=preferred \
    --property hw:numa_nodes=1 \
    --property hw:numa_cpus.0=0,1,2,3 \
    --property hw:numa_mem.0=8192 \
    m1.large_huge

# Create dpdk network
neutron net-create dpdk-net \
    --provider:network_type flat \
    --provider:physical_network physnet2 \
    --router:external "False"

neutron subnet-create \
    --name dpdk-subnet \
    --gateway 22.22.22.1 \
    dpdk-net 22.22.22.0/24

# Create router
neutron router-create dpdk-router
neutron router-interface-add dpdk-router dpdk-subnet
neutron router-gateway-set dpdk-router ext-net

# Create dpdk zone
openstack aggregate create --zone=dpdk dpdk
openstack aggregate add host dpdk host4
openstack aggregate add host dpdk host5

# Create Server
openstack server create \
    --flavor m1.tiny_huge \
    --image cirros \
    --nic net-id=$(neutron net-list | grep dpdk-net | awk '{print $2}') \
    --availability-zone dpdk demo1

# Bond floating ip
floating_ip=$(neutron floatingip-create ext-net | grep floating_ip_address | awk '{print $4}')
nova floating-ip-associate demo1 $floating_ip

