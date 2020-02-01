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
      o) BASEDIR=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

cd ${RUNDIR}

## Set date for hofx
sed -i "s/WINDOW_BEGIN/${window_begin}/g" ${yamlfile}
sed -i "s/WINDOW_LENGTH/${window_length}/g" ${yamlfile}
sed -i "s/BKG_DATE/${bkg_date}/g" ${yamlfile}
sed -i "s/BASE_NAME/${BASEDIR}/g" ${yamlfile}
sed -i "s/MEMBER_NO/${mbr}/g" ${yamlfile}

#
# Setup Jo cost function
#-----------------------

if [ "$NO_ENS_MBR" -gt "1" ]; then 
   OUTDIR="$RUNDIR/hofx/mem${mbr}"
else
   OUTDIR="$RUNDIR/Data"
fi

${ROOT_GODAS_DIR}/scripts/SetupJoCostFunction.sh \
      -i ${yamlfile}                             \
      -d $RUNDIR                                 \
      -o $OUTDIR

echo '#                                                                 #'
echo '#                     prep_hofx3d_yaml.sh                         #'
echo '#=================================================================#'
