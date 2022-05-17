#!/bin/bash

#Command:
#   bash godas_obsplot.sh exp_name variable start_date end_date


while getopts x:v:s:e: flag
do
    case "${flag}" in
        x) exp=${OPTARG};;  # experiment
        v) varname=${OPTARG};;  #variable name
        s) start_date=${OPTARG}Z00;;
        e) end_date=${OPTARG}00;;
    esac
done
echo experiments: $exp
fctl=24
cycle_dir=/work/noaa/marine/jhossen/$exp
echo $cycle_dir
cdir=$PWD/$exp
mkdir $cdir
stv=obs_out

date_YMDH=$(date -ud "$start_date")
YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )

#END_YMDH=$(date -ud "$date_YMDH + ${num_days} days " +%Y%m%d%H )
#echo $YMDH $end_date
year=${YMDH:0:4}
mkdir $cdir/$year
while [ "$YMDH" -le "$end_date" ]; do
    YMD=${YMDH:0:8}
    #echo $YMDH
    mkdir $cdir/$year/$YMD
    plotdir=$cdir/$year/$YMD/ombg
    mkdir $plotdir
    echo plotting dir: $plotdir

    datadir=${cycle_dir}/${stv}/${YMDH:0:4}/${YMDH}/ctrl
    echo data dir: $datadir
    case $varname in
        sst)
        python ./godas_plotobs.py -f $datadir/sst*_l3u_so025.*.nc -g ombg -v sea_surface_temperature -b -2 2 -c jet -q 0 -s $plotdir/sst_superobs.png
        ;;
        adt)
        python ./godas_plotobs.py -f $datadir/adt*.nc -g ombg -v absolute_dynamic_topography -b -.2 .2 -c jet -q 0 -s $plotdir/adt.png
        ;;
        salt)
        python ./godas_plotobs.py -f $datadir/salt*.nc -g ombg -v sea_water_salinity -b -.1 .1 -c jet -q 0 -s $plotdir/salt_profile.png
        ;;
        temp)
        python ./godas_plotobs.py -f $datadir/tem*.nc -g ombg -v sea_water_temperature -b -.2 .2 -c jet -q 0 -s $plotdir/temp_profile.png
        ;;
    esac
    DH=$(($DH+$fctl))
    YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )
done  # day loop



#mv *png $ddir/.
#rm *nc

