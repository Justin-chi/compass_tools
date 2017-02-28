#!/bin/bash
##############################################################################
# File Name:   recreate_repo.sh
# Version:     1.0
# Date:        2017-02-28
# Author:      Maxwell Li
# Email:       liyuenan93@icloud.com
# Blog:        liyuenan.com
# Description: Create repo in centos docker
# Note:        First version
##############################################################################

OPV=kilo

tar -zxvf /centos7-$OPV-ppa.tar.gz
mv /centos7-$OPV-ppa /old_package
rm -rf /centos7-$OPV-ppa.tar.gz

mkdir -p /centos7-$OPV-ppa/{Packages,repodata}

find /old_package -name "*.rpm" | xargs -i cp {} /centos7-$OPV-ppa/Packages/

cp /old_package/comps.xml /centos7-$OPV-ppa/
cp /old_package/ceph_key_release.asc /centos7-$OPV-ppa/
createrepo -g comps.xml /centos7-$OPV-ppa
mkdir /centos7-$OPV-ppa/noarch
mkdir /centos7-$OPV-ppa/noarch/Packages
cp -r /centos7-$OPV-ppa/Packages/ceph* /centos7-$OPV-ppa/noarch/Packages/
cp -r /centos7-$OPV-ppa/repodata/ /centos7-$OPV-ppa/noarch/
tar -zcvf /centos7-$OPV-ppa.tar.gz /centos7-$OPV-ppa
