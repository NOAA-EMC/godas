#!/bin/sh
set -xu

topdir=$(pwd)
echo $topdir

if [ $# -eq 1 ]; then
model=$1
fi
model=${model:-"godas"}

if [ $model = "godas" ]; then

echo soca bundle checkout ... 
if [[ ! -d soca-bundle ]] ; then 
    git clone --branch release/stable-nightly https://github.com/JCSDA/soca-bundle.git
    cd ${topdir}
else 
    echo 'Skip.  Directory soca-bundle already exists.'
fi

echo ufs_godas checkout ...
rm -f ${topdir}/checkout-DATM-MOM6-CICE5.log
if [[ ! -d ufs_godas.fd ]] ; then
    git clone https://github.com/NOAA-EMC/DATM-MOM6-CICE5 DATM-MOM6-CICE5.fd >> ${topdir}/checkout-DATM-MOM6-CICE5.log 2>&1
    cd DATM-MOM6-CICE5.fd
    #git checkout v0.0.0
    git submodule update --init --recursive
    cd ${topdir}
else
    echo 'Skip.  Directory ufs_godas.fd already exists.'
fi
fi

echo UMD-LETKF checkout ...  
if [[ ! -d letkf ]] ; then
    git clone --recursive https://github.com/NOAA-EMC/UMD-LETKF.git letkf 
    cd ${topdir}
else
    echo 'Skip.  Directory letkf already exists.'
fi
