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
# TODO               : Optimize the two inputs
#
# * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # 
# set -x

while getopts "i:d:" opt; do
   case $opt in
      i) yamlfile=("$OPTARG");;
      d) RUNDIR=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

## Setup Jo cost function
##-----------------------

DATADIR=${RUNDIR}/Data

mkdir -p ${DATADIR}

obsdatabase=${DATADIR}/${CDATE} 
echo "obsdatabase="$obsdatabase
# Add adt obs to Jo
obsfile=$obsdatabase/ioda.adt.${DA_SLOT_LEN}h.nc
if [ -f $obsfile ]; then
   echo "Adding ADT to Jo cost function"
   ln -sf ${obsfile} ${DATADIR}/adt.nc
   sed -e '/ADT_JO/{r '${RUNDIR}'/yaml/adt.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
   cp 3dvartmp.yml ${yamlfile}
   rm 3dvartmp.yml
else
   echo "Not assimilating ADT"
fi

# Add sst obs to Jo
obsfile=$obsdatabase/ioda.sst.${DA_SLOT_LEN}h.nc 
if [ -f $obsfile ]; then
   echo "Adding SST to Jo cost function"
   ln -sf ${obsfile} ${DATADIR}/sst.nc
   sed -e '/SST_JO/{r '${RUNDIR}'/yaml/sst.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
   cp 3dvartmp.yml ${yamlfile}
   rm 3dvartmp.yml
else
  echo "Not assimilating SST"
fi

# Add adt insitu profiles to Jo
obsfile=$obsdatabase/ioda.profile.${DA_SLOT_LEN}h.nc 
if [ -f $obsfile ]; then
   echo "Adding Profiles to Jo cost function"
   ln -sf ${obsfile} ${DATADIR}/prof.nc
   sed -e '/INSITU_JO/{r '${RUNDIR}'/yaml/profile.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
   cp 3dvartmp.yml ${yamlfile}
   rm 3dvartmp.yml
else
   echo "Not assimilating profiles"
fi
