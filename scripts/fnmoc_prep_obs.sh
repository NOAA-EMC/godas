#!/bin/bash -l

echo fnmoc_prep_obs.sh starts

#set -x

cd $DCOM_ROOT

OBSDCOM=$DCOM_ROOT/insitu.fnmoc/$PDY
   
OUTDIR=${ROTDIR}/${CDATE}
mkdir -p ${OUTDIR}
   
cd $OBSDCOM
   
for datafilename in profile ship trak
do
   datafile="$OBSDCOM/${PDY}00.${datafilename}"
   
   if [ -f "$datafile" ]; then

      echo "$datafile" from FNMOC for $PDY exist at `pwd`

      s="${IODA_EXEC}/godae_${datafilename}2ioda.py -i " 
      s+=" ${datafile}"
      s+=" -o ${OUTDIR}/ioda.${datafilename}.${DA_SLOT_LEN}h.nc -d ${CDATE}"
      eval ${s}
   
   else
      set -x
      echo There are no $datafile observations for ${CDATE}  
      set +x
   fi
done

echo fnmoc_prep_obs.sh ends

