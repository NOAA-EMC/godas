#!/bin/bash -l

cd $DCOM_ROOT

OBSDCOM=$DCOM_ROOT/insitu.fnmoc/$PDY                           #FullPath of raw obs

#Check if the observations have been preprocessed.

prepobs_found=0
for datafilename in profile ship trak
do

   OUTFILE=ioda.${datafilename}.${DA_SLOT_LEN}h.nc             #Filename of the processed obs
   PREPROCobs=${IODA_ROOT}/${CDATE}/${OUTFILE}                 #FullPath/Filename of preprocessed obs
   PROCobs=${ObsRunDir}/${OUTFILE}                             #FullPath/Filename of observations to be ingested
   
   if [ -f "${PREPROCobs}" ]; then
      echo
      echo PreProcessed Observations are copied from "${PREPROCobs}" \
         to ${PROCobs}

      cp -rf ${PREPROCobs} ${PROCobs}
   
      prepobs_found=1
   fi
done

if [ "$prepobs_found" = 1 ]; then

   echo Preprocessed Observations were copied.
   return

fi
# Check if the raw observations exist and process.

for datafilename in profile ship trak
do

   OUTFILE=ioda.${datafilename}.${DA_SLOT_LEN}h.nc             #Filename of the processed obs
   PREPROCobs=${IODA_ROOT}/${CDATE}/${OUTFILE}                 #FullPath/Filename of preprocessed obs
   PROCobs=${ObsRunDir}/${OUTFILE}                             #FullPath/Filename of observations to be ingested
   RawFileName="$OBSDCOM/${PDY}00.${datafilename}"
   
   if [ -f "$RawFileName" ]; then

      echo "$RawFileName" from FNMOC for $PDY exist at `pwd`

      s="${IODA_EXEC}/godae_${datafilename}2ioda.py -i " 
      s+=" ${RawFileName}"
      s+=" -o ${PROCobs} -d ${CDATE}"
     
      eval ${s}

   else

      echo There are no $RawFileName observations for ${CDATE}  

   fi
done
#
echo fnmoc_prep_obs.sh ends
echo
