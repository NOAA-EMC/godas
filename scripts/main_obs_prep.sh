#!/bin/bash -l
echo 'main_obs_prep.sh starts'
echo ${ROOT_GODAS_DIR}
echo CDATE is $CDATE

ObsRunDir=$RUNCDATE/Data/${CDATE}    #Path for observations to be ingested by DA
mkdir -p ${ObsRunDir}

# Prep absolute dynamic topography obs
source ${ROOT_GODAS_DIR}/scripts/adt_prep_obs.sh 

# Prep T&S profile obs
source ${ROOT_GODAS_DIR}/scripts/fnmoc_prep_obs.sh

# Prep ice concentration obs
source ${ROOT_GODAS_DIR}/scripts/icec_prep_obs.sh

# Prep sst obs
ListOfSST="sst.windsat_l3u.ghrsst \
           sst.gmi_l3u.ghrsst \
           sst.amsr2_l3u.ghrsst
           sst.avhrrmta_l3u.nesdis \
           sst.avhrr19_l3u.nesdis \
           sst.viirs_l3u.nesdis "

for SSTsource in $ListOfSST;do
   ${ROOT_GODAS_DIR}/scripts/sst_prep_obs.sh \
                     -i ${SSTsource}
done

echo main_obs_prep ends

