#!/bin/bash -l

OBSDCOM=$DCOM_ROOT/insitu.fnmoc/$PDY                           #FullPath of raw obs

#Check if the observations have been preprocessed.

prepobs_found=0
for datafilename in profile ship trak
do

   OUTFILE=ioda.${datafilename}.${DA_SLOT_LEN}h.nc             #Filename of the processed obs
   PREPROCobs=${IODA_ROOT}/${CDATE}/${OUTFILE}                 #FullPath/Filename of preprocessed obs
   PROCobs=${ObsRunDir}/${OUTFILE}                             #FullPath/Filename of observations to be ingested
   
   if [ -f "${PREPROCobs}" ]; then
      echo $datafilename
      echo PreProcessed Observations are copied from "${PREPROCobs}" \
           to ${PROCobs}

# Copying files to RUNCDATE
      cp -rp ${PREPROCobs} ${PROCobs}
      echo Preprocessed Observations for $datafilename are copied.   
      prepobs_found=1
   fi

done

if [ $prepobs_found = 1 ]; then
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

      echo "$RawFileName" from FNMOC for $PDY exist and will be processed, \
           obs directory: `pwd`

      s="${IODA_EXEC}/godae_${datafilename}2ioda.py -i " 
      s+=" ${RawFileName}"
      s+=" -o ${PREPROCobs} -d ${CDATE}"
     
      eval ${s}
# Copying files to RUNCDATE
      echo PreProcessed Observations are copied from "${PREPROCobs}" \
           to ${PROCobs}

      cp -rf ${PREPROCobs} ${PROCobs}
      echo PreProcessed Observations for $datafilename are copied

   else

      echo There are no $RawFileName observations for ${PDY}  

   fi
done

#
echo fnmoc_prep_obs.sh ends
echo
