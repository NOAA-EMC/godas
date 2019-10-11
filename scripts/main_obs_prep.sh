#!/bin/bash -l

echo 'main_obs_prep.sh starts'
echo ${ROOT_GODAS_DIR}
echo CDATE is $CDATE

# Prep absolute dynamic topography obs
source ${ROOT_GODAS_DIR}/scripts/adt_prep_obs.sh 
echo "ADT done"

# Prep T&S profile obs
source ${ROOT_GODAS_DIR}/scripts/fnmoc_prep_obs.sh
echo "FNMOC done"

# Prep ice concentration obs
#source ${ROOT_GODAS_DIR}/scripts/icec_prep_obs.sh

# Prep sst obs
ListOfSST="sst.windsat_l3u.ghrsst \
           sst.gmi_l3u.ghrsst \
           sst.amsr2_l3u.ghrsst
           sst.viirs_l3u.nesdis "

for SSTsource in $ListOfSST;do
    sat=''
    echo SSTsource is $SSTsource
    echo sat is $sat
    source ${ROOT_GODAS_DIR}/scripts/sst_prep_obs.sh \
                     -i ${SSTsource} \
                     -d $sat
    mv $OUTDIR/ioda.${SSTsource}.${sat}.${DA_SLOT_LEN}h.nc \
       $OUTDIR/ioda.${SSTsource}.${DA_SLOT_LEN}h.nc  
    echo $SSTsource done
done

# AVHRR data
SSTsource="sst.avhrr_l3u.nesdis"
for sat in AVHRR19 AVHRRMTA; do
   echo "sat is" $sat
   source ${ROOT_GODAS_DIR}/scripts/sst_prep_obs.sh \
                     -i  ${SSTsource} \
                     -d  $sat
   mv $OUTDIR/ioda.${SSTsource}.${sat}.${DA_SLOT_LEN}h.nc \
      $OUTDIR/ioda.sst.${sat}_l3u.nesdis.${DA_SLOT_LEN}h.nc  
# Change filename to lowercase
   cd $OUTDIR
   y=ioda.sst.${sat}_l3u.nesdis.${DA_SLOT_LEN}h.nc 
   lc=`echo $y  | tr '[A-Z]' '[a-z]'`
   if [ $lc != $y ]; then
      mv $y $lc
   fi
   echo $lc
#
   echo $sat done
done

echo main_obs_prep ends

