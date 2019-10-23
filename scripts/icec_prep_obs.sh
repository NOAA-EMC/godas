#!/bin/bash -l 

cd $DCOM_ROOT
OBSDCOM=$DCOM_ROOT/icec_l2.emc                   #FullPath of raw obs
OUTFILE=ioda.icec.cat_l2.emc.${DA_SLOT_LEN}h.nc  #Filename of the processed obs
PREPROCobs=${IODA_ROOT}/${CDATE}/${OUTFILE}     #FullPath/Filename of preprocessed obs
PROCobs=${ObsRunDir}/${OUTFILE}                 #FullPath/Filename of observations to be ingested

#Check if the observations have been preprocessed.
if [ -f "${PREPROCobs}" ]; then
   echo
   echo PreProcessed Observations are copied from "${PREPROCobs}" \
        to ${PROCobs}
   echo

   cp -rf ${PREPROCobs} ${ObsRunDir}/ioda.icec.cat_l2.emc_LARGE.nc

   # Create record dim
   ncks --mk_rec_dmn nlocs ${ObsRunDir}/ioda.icec.cat_l2.emc_LARGE.nc ${ObsRunDir}/icec-tmp.nc
   # Subsample
   ncks -F -d nlocs,1,,5 ${ObsRunDir}/icec-tmp.nc ${PROCobs}
   rm ${ObsRunDir}/icec-tmp.nc
   rm ${ObsRunDir}/ioda.icec.cat_l2.emc_LARGE.nc

   sed -e '/ICEC_emcice_JO/{r '${RUNDIRC}'/yaml/icec.cat_l2.emc.yml' -e 'd}' ${yamlfile}> 3dvartmp.yml 
   cp 3dvartmp.yml ${yamlfile}
   rm 3dvartmp.yml


   return
fi
# Check if the raw observations exist and process.
if [ -d "$OBSDCOM" ]; then

   cd $OBSDCOM
   n=`ls *${PDY}.nc |wc -l`

   if [ $n -gt 0 ]; then 
      s="${IODA_EXEC}/emc_ice2ioda.py -i "
      for files in `ls *${PDY}.nc`; do
        s+=" $OBSDCOM/${files} "
      done
      s+=" -o ${PROCobs} -d ${CDATE}"
      eval ${s}
   else
      echo There are no ICEC observations for ${CDATE}
   fi

fi
