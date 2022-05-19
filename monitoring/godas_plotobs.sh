#!/bin/bash

#Command:
#   bash godas_obsplot.sh -p path/to/exp -x exp_name -t obs_type -s start_date -e end_date


while getopts x:v:s:e:p: flag
do
    case "${flag}" in
        x) exp=${OPTARG};;  # experiment
        v) stv=${OPTARG};;  #variable name
        p) cycle_dir=${OPTARG};;  #path/to/exp
        s) start_date=${OPTARG}Z00;;
        e) end_date=${OPTARG}00;;
    esac
done

echo experiments: $exp
fctl=24
echo 'EXP dir:' $cycle_dir

obslist=(sst adt salt temp sss)

date_YMDH=$(date -ud "$start_date")
YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )
clmp=seismic
year=${YMDH:0:4}
while [ "$YMDH" -le "$end_date" ]; do
    YMD=${YMDH:0:8}
    plotdir=${cycle_dir}/monitoring/$year/$YMD/ombg
    mkdir -p $plotdir
    echo plotting dir: $plotdir
    datadir=${cycle_dir}/${stv}/${YMDH:0:4}/${YMDH}/ctrl
    echo data dir: $datadir
    for obs_type in ${obslist[@]}; do
        echo plotting $obs_type ...
        case $obs_type in
        sst)
        python godas_plotobs.py -f $datadir/sst*_l3u_so025.*.nc -g ombg -v sea_surface_temperature -b -2 2 -c $clmp -q 0 -s $plotdir/sst_superobs.png -t 'sst superobs'
        ;;
        adt)
        python godas_plotobs.py -f $datadir/adt*.nc -g ombg -v absolute_dynamic_topography -b -.2 .2 -c $clmp -q 0 -s $plotdir/adt.png -t 'adt'
        ;;
        salt)
        python godas_plotobs.py -f $datadir/salt*.nc -g ombg -v sea_water_salinity -b -1 3 -c $clmp -q 0 -s $plotdir/salt_profile.png -t 'salt profile'
        ;;
        temp)
        python godas_plotobs.py -f $datadir/temp*.nc -g ombg -v sea_water_temperature -b -1.5 1.5 -c $clmp -q 0 -s $plotdir/temp_profile.png -t 'temp profile'
        ;;
        sss)
        python godas_plotobs.py -f $datadir/sss*.nc -g ombg -v sea_surface_salinity -b -.5 .5 -c $clmp -q 0 -s $plotdir/sss_trak.png -t 'sss trak'
        ;;
        esac
    done #obs_type
    DH=$(($DH+$fctl))
    YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )
done  # day loop


