#!/bin/bash
##############################################################################
# File Name:   load_iso_compass4nfv.sh
# Version:     1.0
# Date:        2017-02-08
# Author:      Maxwell Li
# Email:       liyuenan93@icloud.com
# Blog:        liyuenan.com
# Description: Download newest compass iso
# Note:        First version
##############################################################################

wget http://artifacts.opnfv.org/compass4nfv/latest.properties

ISO_URL=$(sed -e '1,3d' -e '5,6d' -e "s/OPNFV_ARTIFACT_URL=//g" latest.properties)
ISO_NAME=$(sed -e '1,3d' -e '5,6d' -e "s/OPNFV_ARTIFACT_URL=artifacts.opnfv.org\/compass4nfv\///g" latest.properties)

wget $ISO_URL

sha512sum=$(sed -e '1,4d' -e '6,6d' -e "s/OPNFV_ARTIFACT_SHA512SUM=//g" latest.properties)
iso512sum=$(echo $(sha512sum $ISO_NAME) | awk '{print $1}')

if [ $iso512sum==$sha512sum ];then
    echo "+--------------------------------+"
    echo "|  The ISO download completely!  |"
    echo "+--------------------------------+"
else
    echo "+----------------------------------+"
    echo "|  ERROR: The ISO download wrong!  |"
    echo "+----------------------------------+"
fi

rm ./latest.properties
