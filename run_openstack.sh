#!/bin/bash
##############################################################################
# File Name:   run_openstack.sh
# Version:     2.0
# Date:        2017-02-08
# Author:      Maxwell Li
# Email:       liyuenan93@icloud.com
# Blog:        liyuenan.com
# Description: Deploy openstack by compass4nfv
# Note:        First version
##############################################################################

CODE_NAME=compass4nfv
WORK_DIR=$(cd $(dirname ${BASH_SOURCE:-$0});pwd)
cd $WORK_DIR/$CODE_NAME

./build.sh

export ISO_URL=file://$WORK_DIR/$CODE_NAME/work/building/compass.iso

export NETWORK=$WORK_DIR/scenario/network.yml
export DHA=$WORK_DIR/scenario/os-nosdn-nofeature-ha.yml

export OS_VERSION=xenial
#export OS_VERSION=centos7
export OPENSTACK_VERSION=newton

######################### Reconvery
# After restart jumpserver, set these variables and run deploy.sh again.
#export DEPLOY_RECOVERY="true"
#export DEPLOY_FIRST_TIME="false"

######################### Deploy Compass
# If you only need to deploy compass, set this variable.
#export DEPLOY_COMPASS="true"
#export DEPLOY_FIRST_TIME="false"

######################### Deploy Host
# If you only need to deploy host, set these variables.
#export DEPLOY_HOST="true"
#export DEPLOY_FIRST_TIME="false"

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
