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
ListofADT="j1_l2.nesdis \
           j2_l2.nesdis \
           c2_l2.nesdis"
for ADTsource in $ListofADT; do
   obsfile=$obsdatabase/ioda.adt.${ADTsource}.${DA_SLOT_LEN}h.nc
   echo $obsfile
   if [ -f $obsfile ]; then
      echo "Adding ADT to Jo cost function"
      ln -sf ${obsfile} ${DATADIR}/ioda.adt.${ADTsource}.${DA_SLOT_LEN}h.nc
      sed -e '/ADT_'${ADTsource}'_JO/{r '${RUNDIRC}'/yaml/adt.'${ADTsource}'.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
      cp 3dvartmp.yml ${yamlfile}
      rm 3dvartmp.yml
   else
      echo "Not assimilating $ADTsource ADT"
   fi
done

# Add icec obs to Jo (f285-f286 SSMI/SSMIS)
obsfile=$obsdatabase/ioda.icec.cat_l2.emc.${DA_SLOT_LEN}h.nc
echo $obsfile
if [ -f $obsfile ]; then
   echo "Adding ice concentration to Jo cost function"
   ln -sf ${obsfile} ${DATADIR}/ioda.icec.cat_l2.emc.${DA_SLOT_LEN}h.nc
   sed -e '/ICEC_emcice_JO/{r '${RUNDIRC}'/yaml/icec.cat_l2.emc.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
   cp 3dvartmp.yml ${yamlfile}
   rm 3dvartmp.yml
else
   echo "Not assimilating emc icec"
fi

# Add ghrsst to Jo.
ListofSST="windsat_l3u.ghrsst \
           gmi_l3u.ghrsst \
           amsr2_l3u.ghrsst \
           avhrrmta_l3u.nesdis \
           avhrr19_l3u.nesdis"
for SSTsource in $ListofSST; do
   obsfile=$obsdatabase/ioda.sst.${SSTsource}.${DA_SLOT_LEN}h.nc 
   echo $obsfile
   if [ -f $obsfile ]; then
      echo "Adding $SSTsource SST to Jo cost function"
      ln -sf ${obsfile} ${DATADIR}/ioda.sst.${SSTsource}.${DA_SLOT_LEN}h.nc
      sed -e '/SST_'${SSTsource}'_JO/{r '${RUNDIRC}'/yaml/sst.'${SSTsource}'.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
      cp 3dvartmp.yml ${yamlfile}
      rm 3dvartmp.yml
   else
     echo "Not assimilating $SSTsource SST"
   fi
done

# Add insitu profiles to Jo
ListofInsitu="profile \
              ship \
              trak"
for Insitusource in $ListofInsitu; do
   obsfile=$obsdatabase/ioda.${Insitusource}.${DA_SLOT_LEN}h.nc 
   if [ -f $obsfile ]; then
      echo "Adding ${Insitusource} to Jo cost function"
      ln -sf ${obsfile} ${DATADIR}/ioda.${Insitusource}.${DA_SLOT_LEN}h.nc
      sed -e '/INSITU_'${Insitusource}'_JO/{r '${RUNDIRC}'/yaml/'${Insitusource}'.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
      cp 3dvartmp.yml ${yamlfile}
      rm 3dvartmp.yml
   else
      echo "Not assimilating $Insitusource"
   fi
done
