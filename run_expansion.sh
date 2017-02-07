#!/bin/bash
##############################################################################
# File Name: “run_expansion.sh”
# Author：   “LiYuenan”
# mail:      "liyuenan@huawei.com"
##############################################################################

CODE_NAME=compass4nfv_run
WORK_DIR=$(cd $(dirname ${BASH_SOURCE:-$0});pwd)
cd $WORK_DIR/$CODE_NAME

export ISO_URL=file://$WORK_DIR/$CODE_NAME/work/building/compass.iso
export NETWORK=$WORK_DIR/scenario/network_add.yml
export DHA=$WORK_DIR/scenario/virtual_cluster_expansion.yml

export OS_VERSION=trusty
export OPENSTACK_VERSION=mitaka

export EXPANSION="true"
export MANAGEMENT_IP_START="10.1.0.55"
export VIRT_NUMBER=1
export DEPLOY_FIRST_TIME="false"

echo "+--------------------+-------------------------------------------------------------"
echo '| CODE_NAME=         | '$CODE_NAME
echo '| WORK_DIR=          | '$WORK_DIR
echo '| ISO=               | '$ISO_URL
echo '| NEWTORK=           | '$NETWORK
echo '| DHA=               | '$DHA
echo '| OS_VERSION=        | '$OS_VERSION
echo '| OPENSTACK_VERSION= | '$OPENSTACK_VERSION
echo "+--------------------+-------------------------------------------------------------"

./deploy.sh

