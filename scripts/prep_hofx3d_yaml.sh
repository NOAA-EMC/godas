#!/bin/bash
#
# * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # 
#                       Unix Script Documentation 
# 
# Script Name        :
#
# Script Description :
#
# Details            :
#
# Author             :
#
# History Log        :
#
# * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # 
#set -x

echo '#=================================================================#'
echo '#                   prep_hofx3d_yaml.sh starts                    #'
echo '#                                                                 #'

while getopts "i:d:n:" opt; do
   case $opt in
      i) yamlfile=("$OPTARG");;
      d) RUNDIR=("$OPTARG");;
      n) mbr=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

cd ${RUNDIR}
echo "RUNDIR=" $RUNDIR

## Set date for hofx
sed -i "s/WINDOW_BEGIN/${window_begin}/g" ${yamlfile}
sed -i "s/WINDOW_LENGTH/${window_length}/g" ${yamlfile}
sed -i "s/BKG_DATE/${bkg_date}/g" ${yamlfile}
sed -i "s/MEMBER_NO/${mbr}/g" ${yamlfile}
sed -i "s/ocn.pert.ens..nc/MOM.res.nc/g" ${yamlfile}
sed -i "s/cic.pert.ens..nc/cice_bkg.nc/g" ${yamlfile}
sed -i "s/Data/INPUT_MOM6/g" ${yamlfile}

#
# Setup Jo cost function
#-----------------------

${ROOT_GODAS_DIR}/scripts/SetupJoCostFunction.sh \
      -i ${yamlfile}                             \
      -d $RUNDIR

echo '#                                                                 #'
echo '#                     prep_hofx3d_yaml.sh                         #'
echo '#=================================================================#'
