#! /usr/bin/env bash
set -eux

cwd=`pwd`

#---------------------------------------
# build DATM-MOM6-CICE5 
#---------------------------------------
cd DATM-MOM6-CICE5.fd/
./NEMS/NEMSAppBuilder norebuild app=coupled_DATM_MOM6_CICE 
#mv ./NEMS/exe/NEMS.x ./NEMS/exe/nems_datm_mom6_cice5.x
cd $cwd

