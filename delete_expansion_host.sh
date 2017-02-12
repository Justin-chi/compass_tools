#!/bin/bash
##############################################################################
# File Name:   delete_expansion_host.sh
# Version:     1.0
# Date:        2017-02-08
# Author:      Maxwell Li
# Email:       liyuenan93@icloud.com
# Blog:        liyuenan.com
# Description: Delete compute node
# Note:        First version
##############################################################################

# This script used for delet a host when expanse failed.

set -x
hostid="6"
hostname="host$hostid"

virsh destroy $hostname
virsh undefine $hostname

rm -rf work/deploy/vm/$hostname/

set -e
cat work/deploy/switch_machines | awk '{print $2 " " $3 " " $4 " " $5 " " $6 " " $7 " " $8}' > work/deploy/switch_machines

sshpass -p root ssh -o StrictHostKeyChecking=no root@192.168.200.2 "

cat << EOF | mysql
use compass

delete from clusterhost where host_id = $hostid;
delete from host_network where host_id = $hostid;
delete from host where name = \"$hostname\";

select * from clusterhost;
select * from host_network;
select * from host;

EOF

sed -i 2d /etc/compass/switch_machines_file

cobbler system remove --name $hostname
cobbler system list
"
set +e
set +x
echo "===== Delete $hostname Complete ====="

