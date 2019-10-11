#!/bin/bash -l 

while getopts "i:d:" opt; do
   case $opt in
      i) SSTsource=("$OPTARG");;
      d) sat=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

echo DCOM_ROOT=$DCOM_ROOT
cd $DCOM_ROOT

OBSDCOM=$DCOM_ROOT/${sst_source}/$PDY
#set -x
OBSDCOM=$DCOM_ROOT/${SSTsource}/$PDY
echo OBSDCOM = $OBSDCOM
if [ -d "$OBSDCOM" ]; then
   
   OUTDIR=${ROTDIR}/${CDATE}
   mkdir -p ${OUTDIR}
   
   cd $OBSDCOM
   echo SST Observations from ${SSTsource} for $PDY exist at `pwd`

   s="${IODA_EXEC}/gds2_sst2ioda.py -i "
   for files in `ls *${sat}*.nc`; do
      s+=" $OBSDCOM/${files} "
   done
   
   s+=" -o ${OUTDIR}/ioda.${SSTsource}.${sat}.${DA_SLOT_LEN}h.nc -d ${CDATE}"
   eval ${s}
   echo $s

else
   
   set -x
   echo There are no SST observations from ${SSTsource} for ${PDY}  
   set +x

fi

