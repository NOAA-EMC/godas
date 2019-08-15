##!/bin/bash
#set -x
# TO DELETE
DCOMROOT='/scratch3/NCEPDEV/marine/noscrub/Stylianos.Flampouris/ocean_observations/data'
ROTDIR='/scratch3/NCEPDEV/marine/noscrub/marineda/GodasOceanObs'
RUNDIR=''
CDATE=2011100112
PDY=20111001
cyc=12
EXECROOT='/scratch4/NCEPDEV/ocean/noscrub/Stylianos.Flampouris/ioda-conv-dev/update_ioda_converters/ioda-converters/build/bin'
module use -a /home/Stylianos.Flampouris/modulefiles/anaconda

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
