#!/bin/bash -l 
set -e

while getopts "i:d:" opt; do
   case $opt in
      i) SSTsource=("$OPTARG");;
      d) sat=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

<<<<<<< HEAD
echo SST SOURCE = ${SSTsource}

echo DCOM_ROOT=$DCOM_ROOT
=======
echo SST SOURCE = ${sst_source}

>>>>>>> develop
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
   
   # Check if thinning is requiered
   # TODO: This is a temporary fix, thinning should be done as a pre-filter step
   #       in UFO (currently not working)
   echo Processing $sst_source
   case $sst_source in 
      "sst.avhrrmta_l3u.nesdis")
         subsample=true
         skip=250
         ;;
      "sst.avhrr19_l3u.nesdis")
         subsample=true
         skip=250
         ;;
      "sst.windsat_l3u.ghrsst")
         subsample=true
         skip=5
         ;;
   esac
   echo subsample=$subsample
   echo skip=$skip

   if [ $subsample ]; then
      echo "Subsampling $sst_source SST"
      # TODO: Subsample elsewhere
      mv ${PROCobs} ${ObsRunDir}/ioda.sst.${sst_source}_LARGE.nc

      # Create record dim
      ncks --mk_rec_dmn nlocs ${ObsRunDir}/ioda.sst.${sst_source}_LARGE.nc ${ObsRunDir}/sst-tmp.nc
      # Subsample
      ncks -F -d nlocs,1,,$skip ${ObsRunDir}/sst-tmp.nc ${PROCobs}
      # Cleanup
      rm ${ObsRunDir}/sst-tmp.nc
      rm ${ObsRunDir}/ioda.sst.${sst_source}_LARGE.nc   
   fi

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

else
   
   set -x
   echo There are no SST observations from ${SSTsource} for ${PDY}  
   set +x

fi

