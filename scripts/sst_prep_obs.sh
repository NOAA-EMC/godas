#!/bin/bash -l 

while getopts "i:d:" opt; do
   case $opt in
      i) SSTsource=("$OPTARG");;
      d) sat=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

echo SST SOURCE = ${SSTsource}

echo DCOM_ROOT=$DCOM_ROOT
cd $DCOM_ROOT

ObsRunDir=$RUNCDATE/Data    #TODO: Should not be needed here ...
OUTFILE=ioda.${SSTsource}.${sat}.${DA_SLOT_LEN}h.nc  #Filename of the processed obs
PREPROCobs=${IODA_ROOT}/${CDATE}/${OUTFILE}     #FullPath/Filename of preprocessed obs
PROCobs=${ObsRunDir}/${OUTFILE}                 #FullPath/Filename of observations to be ingested


echo "obsrundir: "${ObsRunDir}
echo "obsrundir: "$RUNCDATE/Data

#Check if the observations have been preprocessed.
if [ -f "${PREPROCobs}" ]; then
   echo
   echo PreProcessed Observations are copied from "${PREPROCobs}" \
        to ${PROCobs}
   echo

   cp -rf ${PREPROCobs} ${PROCobs}

   exit
fi

# Check if the raw observations exist and process.
OBSDCOM=$DCOM_ROOT/${SSTsource}/$PDY              #FullPath of raw obs
if [ -d "$OBSDCOM" ]; then
   
   cd $OBSDCOM
   echo SST Observations from ${SSTsource} for $PDY exist and will be processed, obs directory: `pwd` 

   s="${IODA_EXEC}/gds2_sst2ioda.py -i "
   for files in `ls *${sat}*.nc`; do
      s+=" $OBSDCOM/${files} "
   done
   
   s+=" -o ${PROCobs} -d ${CDATE}"
   eval ${s}
   echo ${s}

else
   
   set -x
   echo There are no SST observations from ${SSTsource} for ${PDY}  
   set +x

fi

