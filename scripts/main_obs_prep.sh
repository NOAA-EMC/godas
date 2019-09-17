#!/bin/bash -l
echo 'main_obs_prep.sh starts'
echo ${ROOT_GODAS_DIR}
echo CDATE is $CDATE

ObsRunDir=$RUNDIR/Data/${CDATE}    #Path for observations to be ingested by DA
mkdir -p ${ObsRunDir}

source ${ROOT_GODAS_DIR}/scripts/adt_prep_obs.sh 

source ${ROOT_GODAS_DIR}/scripts/fnmoc_prep_obs.sh

#
#ListOfSST="sst.windsat_l3u.ghrsst sst.amsr2_l3u.ghrsst \
#           sst.avhrr_l3u.nesdis sst.gmi_l3u.ghrsst \
#           sst.viirs_l3u.nesdis "
#
#for SSTsource in $ListOfSST;do
#   ${ROOT_GODAS_DIR}/scripts/sst_prep_obs.sh \
#                     -i ${SSTsource}
#done


# Testing the following
#${ROOT_GODAS_DIR}/scripts/adt_prep_obs.sh
#source ${ROOT_GODAS_DIR}/scripts/sst_windsat_prep_obs.sh
#${ROOT_GODAS_DIR}/scripts/sst_prep_obs.sh \
#      -i sst.windsat_l3u.ghrsst

echo main_obs_prep ends
