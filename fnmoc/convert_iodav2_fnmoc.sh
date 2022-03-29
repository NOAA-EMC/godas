#!/bin/bash

set -eu 

usage="usage: $0 yyyymmdd input_path output_path"
if [[ $# != 3 ]]; then
    echo $usage
    exit 1
fi

date=$1
year=${dtg:0:4}
input_path=$1
output_path=$3

source /work/noaa/ng-godas/spaturi/nggodas_realtime_ext/forCPC/soca-science/configs/machine/machine.hera.intel
module unload anaconda/3.15.1
module load nco/4.9.3

export pySRC=/work/noaa/ng-godas/spaturi/nggodas_realtime_ext/forCPC/build
export PYTHONPATH=${pySRC}/lib/python3.9/pyioda:$PYTHONPATH

cd $output_path
if [ -d $input_path/${date} ]; then
   mkdir -p $date
   for typ in profile ship trak; do
       if [ -f $input_path/${date}/${date}'00'.${typ} ]; then
             echo $input_path/${date}/${date}'00'.${typ}
             python ${pySRC}/bin/godae_${typ}2ioda.py               \
                    -i ${input_path}/${date}/${date}'00'.${typ}              \
                    -o ${output_path}/${date}/insitu_${typ}_fnmoc_${date}.nc \
                    -d ${date}'12'
          echo " "
          echo $typ DONE
          fi
      done 
   fi
   echo " "
echo $dtg DONE
