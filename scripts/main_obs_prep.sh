#!/bin/bash -l

echo 'main_obs_prep.sh starts'
echo CDATE is $CDATE

ObsRunDir=$RUNCDATE/Data/${CDATE}    #Path for observations to be ingested by DA
mkdir -p ${ObsRunDir}

# Prep absolute dynamic topography obs
echo "Prep absolute dynamic topography obs: $DA_ADT"
if [ "$DA_ADT" = True ]; then
   ADTsource=adt.nesdis
   for sat in j1 j2 c2                         # Placeholder to add more satellites
   do
      source ${ROOT_GODAS_DIR}/scripts/adt_prep_obs.sh \
                       -i ${ADTsource} \
                       -d ${sat}
   done
fi

# Prep T&S profile obs
echo "Prep T&S profile obs: $DA_TS"
if [ "$DA_TS" = True ]; then
   source ${ROOT_GODAS_DIR}/scripts/fnmoc_prep_obs.sh
fi

# Prep ice concentration obs
echo "Prep ice concentration obs: $DA_ICEC"
if [ "$DA_ICEC" = True ]; then
   source ${ROOT_GODAS_DIR}/scripts/icec_prep_obs.sh
fi

# Prep sst obs
echo "Prep sst obs: $DA_SST"
if [ "$DA_SST" = True ]; then
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

             echo preprocessing of $SSTsource ${instr} done
         done
      else
         source ${ROOT_GODAS_DIR}/scripts/sst_prep_obs.sh \
                        -i ${SSTsource}

         echo preprocessing of $SSTsource done
      fi
   done
   echo
fi
echo main_obs_prep ends
