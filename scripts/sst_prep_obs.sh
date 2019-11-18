#!/bin/bash -l 
set -e

while getopts "i:" opt; do
   case $opt in
      i) SSTsource=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

# Function for Thinning
thinning_func () {
if $1; then
   echo Subsampling/Thinning $SSTsource SST
   echo subsample =$1
   echo skip =$2
   echo

   mv ${PROCobs} ${ObsRunDir}/ioda.${SSTsource}_LARGE.nc
   # Create record dim
   ncks --mk_rec_dmn nlocs ${ObsRunDir}/ioda.${SSTsource}_LARGE.nc ${ObsRunDir}/sst-tmp.nc
   # Subsample
   ncks -O -F -d nlocs,1,,$2 ${ObsRunDir}/sst-tmp.nc ${PROCobs}
   # Cleanup
   rm ${ObsRunDir}/sst-tmp.nc
   rm ${ObsRunDir}/ioda.${SSTsource}_LARGE.nc
fi   
}

# Get Satellite name and data source from $SSTsource
sat=`echo $SSTsource | awk -F 'sst.|_l3u*' '{print $2}'`
datasource=`echo $SSTsource | awk -F '_' '{print $2}'`

cd $DCOM_ROOT

OUTFILE=ioda.sst.${sat}_${datasource}.${DA_SLOT_LEN}h.nc  #Filename of the processed obs
PREPROCobs=${IODA_ROOT}/${CDATE}/${OUTFILE}               #FullPath/Filename of preprocessed obs
PROCobs=${ObsRunDir}/${OUTFILE}                           #FullPath/Filename of observations to be ingested

echo "obsrundir: "$RUNCDATE/Data/${CDATE}

echo Processing $SSTsource
case $SSTsource in 
   "sst.windsat_l3u.ghrsst")
      sat=WSAT
      subsample=true
      skip=5
      ;; 
   "sst.gmi_l3u.ghrsst")
      sat=GMI
      ;;
   "sst.amsr2_l3u.ghrsst")
      sat=AMSR2
      ;;
   "sst.viirs_l3u.nesdis")
      sat=VIIRS              #TODO: Needs to be checked
      ;;
   "sst.avhrr19_l3u.nesdis")
      sat=AVHRR19
      subsample=true
      skip=250
      ;;
   "sst.avhrrmta_l3u.nesdis")
      sat=AVHRRMTA
      subsample=true
      skip=250
      ;;
esac

#Check if the observations have been preprocessed. 
if [ -f "${PREPROCobs}" ]; then
   echo
   echo PreProcessed Observations for ${SSTsource} are copied from "${PREPROCobs}" \
        to ${PROCobs}
   echo

   # COPY preprocessed Data to RUNCDATE
   cp -rf ${PREPROCobs} ${PROCobs}

   # Apply THINNING
   thinning_func $subsample $skip

else
   
   # Check if the raw observations exist and process.
   if [ "$SSTsource" == "sst.avhrr19_l3u.nesdis" ] || \
      [ "$SSTsource" == "sst.avhrrmta_l3u.nesdis" ]; then
      SSTsource="sst.avhrr_l3u.nesdis"
      OBSDCOM=$DCOM_ROOT/${SSTsource}/$PDY              #FullPath of raw obs
   else
      OBSDCOM=$DCOM_ROOT/${SSTsource}/$PDY              #FullPath of raw obs
   fi

   if [  "$(find $OBSDCOM -name "*$sat*" -print -quit)" ]; then
   
      cd $OBSDCOM
      echo SST Observations from ${SSTsource}-${sat} for $PDY exist and will be processed, obs directory: `pwd` 

      s="${IODA_EXEC}/gds2_sst2ioda.py -i "
      for files in `ls *${sat}*.nc`; do
         s+=" $OBSDCOM/${files} "
      done
   
      s+=" -o ${PREPROCobs} -d ${CDATE}"
      eval ${s}

      echo PreProcessed Observations for ${SSTsource}-${sat} are copied from "${PREPROCobs}" \
           to ${PROCobs}

      # COPY preprocessed Data to RUNCDATE
      cp -rf ${PREPROCobs} ${PROCobs}

      # Apply THINNING
      thinning_func $subsample $skip

   else
      echo There are no SST observations from ${SSTsource}-${sat} for ${PDY}  
   fi
fi

