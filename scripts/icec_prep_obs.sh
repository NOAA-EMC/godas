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

   cp -rf ${PREPROCobs} ${PROCobs}

   return
fi
# Check if the raw observations exist and process.
if [ -d "$OBSDCOM" ]; then

   cd $OBSDCOM

   s="${IODA_EXEC}/emc_ice2ioda.py -i "
   for files in `ls *${PDY}.nc`; do
     s+=" $OBSDCOM/${files} "
   done
   s+=" -o ${PROCobs} -d ${CDATE}"
   echo $s
   eval ${s}

else
   echo There are no ICEC observations
fi
