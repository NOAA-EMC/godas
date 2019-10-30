#!/bin/bash -l

echo 'main_obs_prep.sh starts'
echo ${ROOT_GODAS_DIR}
echo CDATE is $CDATE


ObsRunDir=$RUNCDATE/Data/${CDATE}    #Path for observations to be ingested by DA
mkdir -p ${ObsRunDir}

# Prep absolute dynamic topography obs
ADTsource=adt.nesdis
for sat in j1 j2 c2                         # Placeholder to add more satellites
do
   source ${ROOT_GODAS_DIR}/scripts/adt_prep_obs.sh \
                    -i ${ADTsource} \
                    -d ${sat}
done

# Prep T&S profile obs
source ${ROOT_GODAS_DIR}/scripts/fnmoc_prep_obs.sh

# Prep ice concentration obs
#source ${ROOT_GODAS_DIR}/scripts/icec_prep_obs.sh

# Prep sst obs
ListOfSST="sst.windsat_l3u.ghrsst \
           sst.gmi_l3u.ghrsst \
           sst.amsr2_l3u.ghrsst \
           sst.viirs_l3u.nesdis \
           sst.avhrr_l3u.nesdis"

for SSTsource in $ListOfSST
do
   if [ "$SSTsource" == "sst.avhrr_l3u.nesdis" ]; then
      for instr in avhrr19 avhrrmta; do
          SSTsource=sst.${instr}_l3u.nesdis
          source ${ROOT_GODAS_DIR}/scripts/sst_prep_obs.sh \
                     -i ${SSTsource}

          echo preprocessing of $SSTsource done
      done
   else
      source ${ROOT_GODAS_DIR}/scripts/sst_prep_obs.sh \
                     -i ${SSTsource} 

      echo preprocessing of $SSTsource done
   fi
done
echo

echo main_obs_prep ends

