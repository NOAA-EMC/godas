#! /bin/sh

######################################################################
######################################################################
# Copy outputs:                                                      #
######################################################################
######################################################################

DATA=${RUNCDATE}/fcst

#If a cold mediator start, copy the mediator files:
if [ $inistep = 'cold' ]; then
  cp $DATA/mediator_* $ROTDIR/$CDUMP.$PDY/$cyc/
else
  #copy data from run

  #TODO: THE RESTARTS SHOULD BE COPIED INTO THE NEXT $cyc file? or PDY?
  #or should the restarts from before be copied in a different dir?
  #restart file from each component
  mkdir -p $ROTDIR/$CDUMP.$PDY/$cyc/restart
  mkdir -p $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_RESTART
  cp $DATA/restart/* $ROTDIR/$CDUMP.$PDY/$cyc/restart/
  cp $DATA/MOM6_RESTART/* $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_RESTART/
  cp $DATA/mediator_* $ROTDIR/$CDUMP.$PDY/$cyc/

  #MOM6 output:
  mkdir -p  $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_OUTPUT
  cp $DATA/SST_*.nc $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_OUTPUT/
  cp $DATA/ocn_*.nc $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_OUTPUT/
  cp $DATA/MOM6_OUTPUT/* $ROTDIR/$CDUMP.$PDY/$cyc/MOM6_OUTPUT/

  #CICE output:
  mkdir -p  $ROTDIR/$CDUMP.$PDY/$cyc/CICE_history
  cp $DATA/history/* $ROTDIR/$CDUMP.$PDY/$cyc/CICE_history/

fi


