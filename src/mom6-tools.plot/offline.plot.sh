#!/bin/bash

CASES_NUM=$#
#0. check number of input cases
if [ $CASES_NUM -lt 1 ]; then
        echo "Path for project name is empty: ./offline.plot.sh path_for_case1 ..."
        exit 0
fi

for i in "$@"; do
  CASE_PATH=$i
  echo "Creating post processing plots for case: $CASE_PATH"

  #1. set PATHs for case to make plots
  if [ -f $CASE_PATH/config.base ]; then
      source $CASE_PATH/config.base

      #2. png files: saved in Figures directory of $RUNCDATE/Figures
      dirs=$(ls $RUNDIR |  grep '^[0-9]*$' )

      for f in $dirs; do
	  if [ -d $RUNDIR/${f} ]; then
              export CDATE=$f
	      echo $CDATE
	      export RUNCDATE=$RUNDIR/$CDATE
	      export FiguresDir=$RUNCDATE/Figures
	      export IceAnlDir=$RUNDIR/$CDATE/Data
	      export OceanFcstDir=$RUNDIR/$CDATE/fcst

	      source $MOD_PATH/godas.python
	      source $ROOT_GODAS_DIR/scripts/post_plot.sh
	  fi
      done
  else
      echo 'config.base does not exists: '$CASE_PATH
  fi
done
