#! /usr/bin/env bash
set -eux

cwd=`pwd`

#---------------------------------------
# build ufs DATM-MOM6-CICE5 (godas) app
#---------------------------------------
cd ufs_godas.fd/
./NEMS/NEMSAppBuilder norebuild app=coupled_DATM_MOM6_CICE 
#mv ./NEMS/exe/NEMS.x ./NEMS/exe/nems_datm_mom6_cice5.x
cd $cwd

