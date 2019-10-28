#!/bin/bash -l 

while getopts "i:d:" opt; do
   case $opt in
      i) ADTsource=("$OPTARG");;
      d) sat=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

cd $DCOM_ROOT

ObsRunDir=$RUNCDATE/Data                               #TODO: Should not be needed here ...
OUTFILE=ioda.adt.${sat}_l2.nesdis.${DA_SLOT_LEN}h.nc   #Filename of the processed obs
PREPROCobs=${IODA_ROOT}/${CDATE}/${OUTFILE}            #FullPath/Filename of preprocessed obs
PROCobs=${ObsRunDir}/${OUTFILE}                        #FullPath/Filename of observations to be ingested

#Check if the observations have been preprocessed.
if [ -f "${PREPROCobs}" ]; then
   echo
   echo PreProcessed Observations are copied from "${PREPROCobs}" \
        to ${PROCobs}
   echo

   cp -rf ${PREPROCobs} ${PROCobs}
   echo Preprocessed Observations for ADT $sat are copied.
   return
fi

# Check if the raw observations exist and process.
OBSDCOM=$DCOM_ROOT/${ADTsource}/$PDY              #FullPath of raw obs
if [ -d "$OBSDCOM" ]; then
    
   cd $OBSDCOM
   
   echo ADT Observations from ${ADTsource} for $PDY exist and will be processed, \
        obs directory: `pwd` 
   
   s="${IODA_EXEC}/rads_adt2ioda.py -i "
   for files in `ls *${sat}*.nc`; do
      s+=" $OBSDCOM/${files} "
   done
   
   s+=" -o ${PREPROCobs} -d ${CDATE}"
   
   eval ${s}
# Copying files to RUNCDATE
   echo PreProcessed Observations are copied from "${PREPROCobs}" \
        to ${PROCobs}

   cp -rf ${PREPROCobs} ${PROCobs}
   echo PreProcessed Observations for ${ADTsource} $sat are copied


else
   
   echo There are no ADT observations from ${ADTsource} $sat for ${PDY}  

fi

