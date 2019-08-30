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

while getopts "i:d:" opt; do
   case $opt in
      i) yamlfile=("$OPTARG");;
      d) RUNDIR=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

cd ${RUNDIR}

## Set date for hofx
sed -i "s/WINDOW_BEGIN/${window_begin}/g" ${yamlfile}
sed -i "s/WINDOW_LENGTH/${window_length}/g" ${yamlfile}
sed -i "s/BKG_DATE/${bkg_date}/g" ${yamlfile}
#
# Setup Jo cost function
#-----------------------

${ROOT_GODAS_DIR}/scripts/SetupJoCostFunction.sh \
      -i ${yamlfile}                             \
      -d $RUNDIR

echo '#                                                                 #'
echo '#                     prep_hofx3d_yaml.sh                         #'
echo '#=================================================================#'
