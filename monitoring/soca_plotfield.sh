#!/bin/bash

#Command:
#   bash soca_plotfield.sh -x exp_name -v state_vector -s start_date -e end_date

function prepsurfyaml {
cat <<EOF
variable: $1
clim:
  min: $2
  max: $3
time: $4
level: $5
latitude: 0.0
aggregate: False
projection: $6 #'global'
experiment: $7 
plot_dir: $8
color: $9  # Spectral  #seismic #jet 
EOF
}

while getopts x:v:s:e: flag
do
    case "${flag}" in
        x) exp=${OPTARG};;  # experiment
        v) stv=${OPTARG};;  #state vector
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
varlist=(Temp Salt ave_ssh aicen hicen)
projlist=(global north south)
#tlist=($(seq 0 50 100))
tlist=(50) # list of time indices to plot
LEVEL=1
date_YMDH=$(date -ud "$start_date")
YMDH=$(date -ud "$date_YMDH " +%Y%m%d%H )
clmp=jet
year=${YMDH:0:4}
mkdir $cdir/$year
while [ "$YMDH" -le "$end_date" ]; do
    YMD=${YMDH:0:8}
    mkdir $cdir/$year/$YMD
    plotdir=$cdir/$year/$YMD/$stv
    mkdir $plotdir
    echo plotting dir: $plotdir

    datadir=${cycle_dir}/${stv}/${YMDH:0:4}/${YMDH}/ctrl
    if [ $stv == incr ]; then
        clmp=seismic
        hrp=${YMDH:9:10}
        YMDH_i=$(date -ud "${YMD}Z$hrp" +%Y-%m-%dT%H:%M:%S)
        echo $YMDH $YMDH_i
    fi
    for proj in ${projlist[@]}; do
        for tindex in ${tlist[@]} ;do
            for varname in ${varlist[@]}; do
                case $varname in
                    ave_ssh)
                    if [ $stv == incr ]; then
                        FNAME=ocn.var.iter1.${stv}.${YMDH_i}Z.nc
                        prepsurfyaml $varname -.1 .1 $tindex surface $proj $stv $plotdir $clmp > ${stv}.yaml
                    else
                        FNAME=ocn.${stv}.${YMDH}.nc
                        prepsurfyaml $varname -2 1 $tindex surface $proj $stv $plotdir  $clmp > ${stv}.yaml
                    fi 
                    ;;
                    Salt)
                    if [ $stv == incr ]; then
                        FNAME=ocn.var.iter1.${stv}.${YMDH_i}Z.nc
                        prepsurfyaml $varname -.1 0.1 $tindex $LEVEL $proj $stv $plotdir $clmp > ${stv}.yaml
                    else
                        FNAME=ocn.${stv}.${YMDH}.nc
                        prepsurfyaml $varname 30 38 $tindex $LEVEL $proj $stv $plotdir $clmp > ${stv}.yaml
                    fi
                    ;;
                    Temp)
                    if [ $stv == incr ]; then
                        FNAME=ocn.var.iter1.${stv}.${YMDH_i}Z.nc
                        prepsurfyaml ${varname} -2.0 2.0 $tindex $LEVEL $proj $stv $plotdir $clmp > ${stv}.yaml
                    else
                        FNAME=ocn.${stv}.${YMDH}.nc
                        prepsurfyaml $varname -2 32 $tindex $LEVEL $proj $stv $plotdir $clmp > ${stv}.yaml
                    fi 
                    ;;
                    aicen)  # bound [0 1]
                    if [ $proj != 'global' ] ; then
                        if [ $stv == incr ]; then
                            FNAME=ice.var.iter1.${stv}.${YMDH_i}Z.nc
                            prepsurfyaml $varname -0.1 0.1 $tindex surface $proj $stv $plotdir $clmp > ${stv}.yaml
                        else
                            FNAME=ice.${stv}.${YMDH}.nc
                            prepsurfyaml $varname 0 1 $tindex surface $proj $stv $plotdir $clmp > ${stv}.yaml
                        fi
                    else
                        continue
                    fi
                    ;;
                    hicen)  # bound [0 5]
                    if [ $proj != 'global' ]; then
                        if [ $stv == incr ]; then
                            FNAME=ice.var.iter1.${stv}.${YMDH_i}Z.nc
                            prepsurfyaml $varname -0.1 0.1 $tindex surface $proj $stv $plotdir $clmp > ${stv}.yaml
                        else
                            FNAME=ice.${stv}.${YMDH}.nc
                            prepsurfyaml $varname 0 4 $tindex surface $proj $stv $plotdir $clmp > ${stv}.yaml
                        fi
                    else
                        continue
                    fi
                    ;;
                esac
                echo plotting $varname in the $proj # using $FNAME
                ./soca_plotfield.py -g $cycle_dir/static/soca_gridspec.nc -f $datadir/$FNAME \
                             -s horizontal -y ${stv}.yaml
          done  #tindex
      done  #varname
    done    #projlist
    DH=$(($DH+$fctl))
    YMDH=$(date -ud "$date_YMDH + $DH hours" +%Y%m%d%H )
done  # day loop


