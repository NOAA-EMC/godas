#!/bin/bash -l 

while getopts "i:" opt; do
   case $opt in
      i) sst_source=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

echo SST SOURCE = ${sst_source}


cd $DCOM_ROOT

OBSDCOM=$DCOM_ROOT/${sst_source}/$PDY
if [ -d "$OBSDCOM" ]; then
   
   OUTDIR=${ROTDIR}/${CDATE}
   mkdir -p ${OUTDIR}
   
   cd $OBSDCOM
   echo SST Observations from ${sst_source} for $PDY exist at `pwd`
   
   s="${IODA_EXEC}/gds2_sst2ioda.py -i "
   for files in `ls *.nc`; do
      s+=" $OBSDCOM/${files} "
   done
   
   s+=" -o ${OUTDIR}/ioda.${sst_source}.${DA_SLOT_LEN}h.nc -d ${CDATE}"

   eval ${s}

else
   
   set -x
   echo There are no SST observations from ${sst_source} for ${CDATE}  
   set +x

fi
 
