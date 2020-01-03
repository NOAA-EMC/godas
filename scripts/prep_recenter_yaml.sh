#!/bin/bash -l 
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
# set -x
echo '#=================================================================#'
echo '#                    prep_recenter_yaml.sh starts                 #'
echo ' '

while getopts "i:d:n:" opt; do
   case $opt in
      i) yamlfile=("$OPTARG");;
      d) RUNDIR=("$OPTARG");;
      n) mbr=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

cd ${RUNDIR}
pwd

sed -i "s/BKG_DATE/${bkg_date}/g" ${yamlfile}

MEMBER_NO=1

while [[ $MEMBER_NO -le $mbr ]]
do
   echo "- <<: *_file"  >> recenter_members
   echo "   ocn_filename: ./Data/ocn.pert.ens."$MEMBER_NO".nc" &>> recenter_members
   echo "   ice_filename: ./Data/ice.ana."$MEMBER_NO".nc" &>> recenter_members

   ((MEMBER_NO = MEMBER_NO + 1))
done
sed -e '/ENSEMBLE_FILES/ {' -e 'r  recenter_members' -e 'd' -e '}' -i  ${yamlfile}

echo '#                    prep_recenter_yaml.sh starts                 #'
echo '#=================================================================#'
echo ' '

