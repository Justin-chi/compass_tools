#!/bin/bash
##############################################################################
# File Name: "openstack_test.sh"
# Author:    "LiYuenan"
# mail:      "liyuenan@huawei.com"
##############################################################################

set -x
set -e

# source the admin credentials to gain access to admin-only CLI commands:
source /opt/admin-openrc.sh

########## Test Keyteone ##########
# As the admin user, request an authentication token:
openstack token issue

########## Test Glance ##########
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

# List the image
glance image-list

########## Test Nova ##########
openstack compute service list

########## Test Neutron ##########
# List loaded extensions to verify successful launch of the neutron-server process:
neutron ext-list

# List agents to verify successful launch of the neutron agents:
openstack network agent list

########## Test Cinder ##########
# List service components to verify successful launch of each process:
openstack volume service list

########## Test Heat ##########
# List service components to verify successful launch and registration of each process:
openstack orchestration service list

########## Test Ceilometer ##########
# List available meters:
ceilometer meter-list

# Download the CirrOS image from the Image service:
IMAGE_ID=$(glance image-list | grep 'cirros' | awk '{ print $2 }')
glance image-download $IMAGE_ID > /tmp/cirros.img

# List available meters again to validate detection of the image download:
ceilometer meter-list

# Retrieve usage statistics from the image.download meter:
ceilometer statistics -m image.download -p 60

# Remove the previously downloaded image file /tmp/cirros.img:
rm /tmp/cirros.img

########## Test Ceilometer ##########
# List aodh alarm
aodh alarm list

set +x
set +e

echo "===== Test Pass! ====="
