#!/bin/bash -l 

cd $DCOMROOT

OBSDCOM=$DCOMROOT/adt.nesdis/$PDY
if [ -d "$OBSDCOM" ]; then
   
   OUTDIR=${ROTDIR}/${CDATE}
   mkdir -p ${OUTDIR}
   echo ${OUTDIR}
   
   cd $OBSDCOM
   echo ADT Observations for $PDY exist at `pwd`
   
   s="${IODA_EXEC}/rads_adt2ioda.py -i "
   for files in `ls *.nc`; do
      s+=" $OBSDCOM/${files} "
   done
   
   s+=" -o ${OUTDIR}/ioda.adt.${DA_SLOT_LEN}h.nc -d ${CDATE}"

   eval ${s}

else
   
   set -x
   echo There are no ADT observations for ${CDATE}  
   set +x

fi
 
