##!/bin/bash
#set -x
# TO DELETE

# END TO DELETE

cd $DCOMROOT

ADTDCOM=$DCOMROOT/adt.nesdis/$PDY
if [ -d "$ADTDCOM" ]; then
   
   OUTDIR=${ROTDIR}/${CDATE}
   mkdir -p ${OUTDIR}
   echo ${OUTDIR}
   
   cd $ADTDCOM
   echo ADT Observations for $PDY exist at `pwd`
   
   s="${EXECROOT}/rads_adt2ioda.py -i "
   for files in `ls *.nc`; do
      s+=" $ADTDCOM/${files} "
   done
   
   s+=" -o ${OUTDIR}/ioda.adt.nc -d ${CDATE}"
fi
 
eval $s

exit 
