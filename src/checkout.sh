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
    git clone --branch master https://github.com/JCSDA/soca-bundle.git 
    cd ${topdir}
else 
    echo 'Skip.  Directory soca-bundle already exists.'
fi

echo ufs_godas checkout ...
rm -f ${topdir}/checkout-ufs_godas.log
if [[ ! -d ufs_godas.fd ]] ; then
    git clone gerrit:EMC_DATM-MOM6-CICE5 ufs_godas.fd >> ${topdir}/checkout-ufs_godas.log 2>&1
    cd ufs_godas.fd
    git checkout v0.0.0
    git submodule update --init --recursive
    cd ${topdir}
else
    echo 'Skip.  Directory ufs_godas.fd already exists.'
fi
fi

