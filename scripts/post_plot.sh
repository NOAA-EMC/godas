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

GridFile=$(find `pwd` -name 'ocn_*.nc' -print -quit)

# 1. Plot Ice analysis
cp -rf $IceAnlDir/cic.socagodas.an.*.nc $OceanFcstDir

python $SOCA_EXEC/ice.plot.py                      \
         -grid $GridFile                           \
         -data $OceanFcstDir/cic.socagodas.an.*.nc \
         -figs_path $FiguresDir                    \
         -var hice aice

# 2. Plot the ocean fcst 
python $SOCA_EXEC/sfc.plot.py                      \
         -grid $GridFile                           \
         -data $OceanFcstDir/ocn_*.nc              \
         -figs_path  $FiguresDir 

# 3. Plot time averages
[ ! -d $FiguresDir ] && mkdir -p $FiguresDir/time_mean

python $SOCA_EXEC/sfc.time.plot.py                 \
         -grid $GridFile                           \
         -data $OceanFcstDir/ocn_*.nc              \
         -figs_path $FiguresDir/time_mean

