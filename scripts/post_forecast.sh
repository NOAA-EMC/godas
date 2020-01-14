#! /bin/sh -l


echo "Entering post run forecast script"

while getopts "n:" opt; do
   case $opt in
      n) mbr=("$OPTARG");;
   esac
done
shift $((OPTIND -1))


######################################################################
######################################################################
# Copy IC/Restarts:                                                  #
######################################################################
######################################################################

if [ -z "$mbr" ]
then 
   DATA=${RUNCDATE}/fcst
   nextic=$RUNCDATE/../NEXT_IC
else
   DATA=${RUNCDATE}/fcst/mem$mbr
   nextic=$RUNCDATE/../NEXT_IC/mem$mbr
fi

#TODO: If a cold mediator start, copy the mediator files:
##  if [ $inistep = 'cold' ]; then
##   cp $DATA/mediator_* $ROTDIR/$CDUMP.$PDY/$cyc/

mkdir -p ${nextic}/restart

echo "Forecast Run Dir is: $DATA"
echo "NEXT_IC dir is: ${nextic}"

echo "Copy restarts for ice"
cp $DATA/restart/* ${nextic}/restart/
echo "Copy mediator restarts"
cp $DATA/mediator_* ${nextic}/
echo "Copy MOM6 Restarts"
cp $DATA/MOM6_RESTART/* ${nextic}/


#  #TODO: THE RESTARTS SHOULD BE COPIED INTO THE NEXT $cyc file? or PDY?
#  #or should the restarts from before be copied in a different dir?
#  #restart file from each component
#  mkdir -p $ROTDIR/$CDUMP.$PDY/$cyc/restart
#  mkdir -p $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_RESTART
#  cp $DATA/restart/* $ROTDIR/$CDUMP.$PDY/$cyc/restart/
#  cp $DATA/MOM6_RESTART/* $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_RESTART/
#  cp $DATA/mediator_* $ROTDIR/$CDUMP.$PDY/$cyc/

######################################################################
######################################################################
# Copy Output:                                                       #
######################################################################
######################################################################
#TODO: Where do we store output we want to keep...

#  #MOM6 output:
#  mkdir -p  $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_OUTPUT
#  cp $DATA/SST_*.nc $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_OUTPUT/
#  cp $DATA/ocn_*.nc $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_OUTPUT/
#  cp $DATA/MOM6_OUTPUT/* $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_OUTPUT/
#
#  #CICE output:
#  mkdir -p  $ROTDIR/$CDUMP.$PDY/$cyc/CICE_history
#  cp $DATA/history/* $ROTDIR/$CDUMP.$PDY/$cyc/CICE_history/


######################################################################
######################################################################
# Cleanup forecast dir:                                              #
######################################################################
######################################################################

#TODO:
#After moving output to other dir, remove $DATA dir
