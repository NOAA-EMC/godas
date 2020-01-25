#!/bin/bash -l

echo "post_plot_fcst.sh starts"
echo "CDATE is " $CDATE
cd $RUNCDATE
echo "Location of experiment: "`pwd` 

IceAnlDir=$RUNCDATE/Data
OceanFcstDir=$RUNCDATE/fcst
FiguresDir=$RUNCDATE/Figures

[ ! -d $FiguresDir ] && mkdir -p $FiguresDir

echo "Figures are created at $FigureDir"

GridFile=$(find $OceanFcstDir -name 'ocn_*.nc' -print -quit)
if [[ -z "$GridFile" ]] ; then
    echo "Grid file containing geolon/geolat does not exist ..."
    exit 1
fi

# 1. Plot Ice analysis
files2plot=( "$IceAnlDir"/cic.socagodas.an.*.nc )
if [ -e "${files2plot[0]}" ]; then
    cp -rf $IceAnlDir/cic.socagodas.an.*.nc $OceanFcstDir
    python $SOCA_EXEC/ice.plot.py                    \
           -grid $GridFile                           \
           -data $OceanFcstDir/cic.socagodas.an.*.nc \
           -figs_path $FiguresDir                    \
           -var hice aice
fi

# 2. Plot the ocean fcst 
files2plot=( "$OceanFcstDir"/ocn_*.nc )
if [ -e "${files2plot[0]}" ]; then
    python $SOCA_EXEC/sfc.plot.py                    \
	   -grid $GridFile                           \
	   -data $OceanFcstDir/ocn_*.nc              \
	   -figs_path $FiguresDir 
fi

# 3. Plot time averages
[ ! -d $FiguresDir ] && mkdir -p $FiguresDir/time_mean

files2plot=( "$OceanFcstDir"/ocn_*.nc )
if [ -e "${files2plot[0]}" ]; then
    python $SOCA_EXEC/sfc.time.plot.py               \
           -grid $GridFile                           \
           -data $OceanFcstDir/ocn_*.nc              \
           -figs_path $FiguresDir/time_mean
fi
