#!/bin/bash -l 

cd $DCOM_ROOT

OBSDCOM=$DCOM_ROOT/sst.windsat_l3u.ghrsst/$PDY
if [ -d "$OBSDCOM" ]; then
   
   OUTDIR=${ROTDIR}/${CDATE}
   mkdir -p ${OUTDIR}
   
   cd $OBSDCOM
   echo SST Observations from WindSat for $PDY exist at `pwd`
   
   s="${IODA_EXEC}/gds2_sst2ioda.py -i "
   for files in `ls *.nc`; do
      s+=" $OBSDCOM/${files} "
   done
   
   s+=" -o ${OUTDIR}/ioda.sst.${DA_SLOT_LEN}h.nc -d ${CDATE}"

   eval ${s}

else
   
   set -x
   echo There are no SST observations from WindSat for ${CDATE}  
   set +x

fi
 
