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
      d) RUNDIRC=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

## Setup Jo cost function
##-----------------------

DATADIR=${RUNDIRC}/Data

mkdir -p ${DATADIR}

obsdatabase=${DATADIR}/${CDATE} 
echo "obsdatabase="$obsdatabase
# Add adt obs to Jo
obsfile=$obsdatabase/ioda.adt.${DA_SLOT_LEN}h.nc
echo $obsfile
if [ -f $obsfile ]; then
   echo "Adding ADT to Jo cost function"
   ln -sf ${obsfile} ${DATADIR}/adt.nc
   sed -e '/ADT_JO/{r '${RUNDIRC}'/yaml/adt.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
   cp 3dvartmp.yml ${yamlfile}
   rm 3dvartmp.yml
else
   echo "Not assimilating ADT"
fi

# Add ghrsst to Jo.
# HACK: sst preproc obs lost inst name ...
obsfile=$obsdatabase/ioda.sst.${DA_SLOT_LEN}h.nc 
echo $obsfile
echo "Adding $inst SST to Jo cost function"
ln -sf ${obsfile} ${DATADIR}/ioda.sst.windsat_l3u.ghrsst.nc
sed -e '/SST_windsat_JO/{r '${RUNDIRC}'/yaml/sst.windsat_l3u.ghrsst.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml                                                                                           
cp 3dvartmp.yml ${yamlfile}                                                                                                                                                                              
rm 3dvartmp.yml

#ListOfGHRSST="sst windsat gmi amsr2"
#for inst in $ListOfGHRSST; do
#   obsfile=$obsdatabase/ioda.sst.${inst}_l3u.ghrsst.${DA_SLOT_LEN}h.nc 
#   echo $obsfile
#   if [ -f $obsfile ]; then
#      echo "Adding $inst SST to Jo cost function"
#      ln -sf ${obsfile} ${DATADIR}/ioda.sst.${inst}_l3u.ghrsst.nc
#      echo SST_${inst}_JO
#      echo sst.${inst}_l3u.ghrsst.yml
#      sed -e '/SST_'${inst}'_JO/{r '${RUNDIRC}'/yaml/sst.'${inst}'_l3u.ghrsst.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
#      cp 3dvartmp.yml ${yamlfile}
#      rm 3dvartmp.yml
#   else
#     echo "Not assimilating $inst SST"
#   fi
#done

# Add insitu profiles to Jo
obsfile=$obsdatabase/ioda.profile.${DA_SLOT_LEN}h.nc 
if [ -f $obsfile ]; then
   echo "Adding Profiles to Jo cost function"
   ln -sf ${obsfile} ${DATADIR}/prof.nc
   sed -e '/INSITU_JO/{r '${RUNDIRC}'/yaml/profile.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
   cp 3dvartmp.yml ${yamlfile}
   rm 3dvartmp.yml
else
   echo "Not assimilating profiles"
fi
