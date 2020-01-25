#!/bin/bash

#1. set CLONE_DIR and RUN_DIR/PROJECT_NAME containing data files to plot
export CLONE_DIR=/scratch2/NCEPDEV/marineda/Jong.Kim/godas_wk
export RUN_DIR=/scratch1/NCEPDEV/stmp2/Jong.Kim/Jong.Kim/rundir
export PROJECT_NAME=workflow_diag

#2. png files: saved in Figures directory of $RUNCDATE/Figures
export SOCA_EXEC=$CLONE_DIR/build/bin
export MOD_PATH=$CLONE_DIR/modulefiles
export ROOT_GODAS_DIR=$CLONE_DIR
dirs=$(ls $RUN_DIR/$PROJECT_NAME)

for f in $dirs; do
    if [ -d $RUN_DIR/$PROJECT_NAME/${f} ]; then
	if [[ $f =~ "19" || $f =~ "20" ]]; then
            export CDATE=$f
	    echo $CDATE
	    export RUNCDATE=$RUN_DIR/$PROJECT_NAME/$CDATE
	    export FiguresDir=$RUNCDATE/Figures
	    export IceAnlDir=$RUN_DIR/$PROJECT_NAME/$CDATE/Data
	    export OceanFcstDir=$RUN_DIR/$PROJECT_NAME/$CDATE/fcst

	    source $MOD_PATH/godas.python
	    source $CLONE_DIR/scripts/post_plot.sh
	fi
    fi
done
