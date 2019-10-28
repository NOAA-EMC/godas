#!/bin/bash -l 
set -e

while getopts "i:" opt; do
   case $opt in
      i) SSTsource=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

echo SST SOURCE = ${SSTsource}
sat=`echo $SSTsource | awk -F 'sst.|_l3u*' '{print $2}'`
datasource=`echo $SSTsource | awk -F '_' '{print $2}'`
echo $sat $datasource

echo DCOM_ROOT=$DCOM_ROOT
cd $DCOM_ROOT

ObsRunDir=$RUNCDATE/Data                                  #TODO: Should not be needed here ...
OUTFILE=ioda.sst.${sat}_${datasource}.${DA_SLOT_LEN}h.nc  #Filename of the processed obs
PREPROCobs=${IODA_ROOT}/${CDATE}/${OUTFILE}               #FullPath/Filename of preprocessed obs
PROCobs=${ObsRunDir}/${OUTFILE}                           #FullPath/Filename of observations to be ingested

echo "obsrundir: "${ObsRunDir}
echo "obsrundir: "$RUNCDATE/Data

#Check if the observations have been preprocessed.
echo Processing $SSTsource
case $SSTsource in 
   "sst.windsat_l3u.ghrsst")
      echo $PREPROCobs
      echo $PROCobs
      sat=WSAT
      ;; 
   "sst.gmi_l3u.ghrsst")
      echo $PREPROCobs
      echo $PROCobs
      sat=GMI
       ;;
   "sst.amsr2_l3u.ghrsst")
      echo $PREPROCobs
      echo $PROCobs
      sat=AMSR2
       ;;
   "sst.viirs_l3u.nesdis")
      echo $PREPROCobs
      echo $PROCobs
      sat=VIIRS              #TODO: Needs to be checked
       ;;
   "sst.avhrr19_l3u.nesdis")
      echo $PREPROCobs
      echo $PROCobs
      sat=AVHRR19
      ;;
   "sst.avhrrmta_l3u.nesdis")
      echo $PREPROCobs
      echo $PROCobs
      sat=AVHRRMTA
      ;;
esac
 
if [ -f "${PREPROCobs}" ]; then
   echo
   echo PreProcessed Observations are copied from "${PREPROCobs}" \
        to ${PROCobs}
   echo

   cp -rp ${PREPROCobs} ${PROCobs}
   
   # Check if thinning is required
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

   return
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
   
   s+=" -o ${PREPROCobs} -d ${CDATE}"
   eval ${s}
# Copying files to RUNCDATE
      echo PreProcessed Observations are copied from "${PREPROCobs}" \
           to ${PROCobs}

      cp -rf ${PREPROCobs} ${PROCobs}
      echo PreProcessed Observations for $SSTsource are copied.

else
   
   set -x
   echo There are no SST observations from ${SSTsource} for ${PDY}  
   set +x
fi

