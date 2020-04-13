#!/bin/sh
set -ue

topdir=$(pwd)
echo $topdir

if [ $# -eq 1 ]; then
  model=$1
fi
model=${model:-"godas"}

if [ $# -eq 2 ]; then
  hpc=$2
fi

if [ $model = "godas" ]; then
  case $hpc in

  hera) 
     ln -sf /scratch2/NCEPDEV/marineda/godas_input/FIX/* $topdir/../fix/
     ;;

  orion)
     ln -sf /work/noaa/marine/marineda/godas_input/FIX/* $topdir/../fix/
     ;;

  *)
  #TODO generalize  (should put on hpss eventually too)
    echo "The HPC is unknown, please add the location of the FIX files, exiting..."
    exit
esac
fi
