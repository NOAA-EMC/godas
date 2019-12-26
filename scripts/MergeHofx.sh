#!/bin/bash -l

echo 'MergingHofx starts...'
echo ' '

while getopts "i:" opt; do
   case $opt in
      i) inputdir=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

cd ${inputdir}

filenames=($(ls *.out_*.nc | cut -d '.' -f 1,2,3 | sort -u ))

for ifile in "${filenames[@]}"; do
   out_name=($(echo $ifile | cut -d '.' -f 2,3))
   ncks -O -h --mk_rec_dmn nlocs ${ifile}*out_0000.nc ${ifile}*out_0000.nc
   ncrcat -h  ${ifile}*out_*.nc HofX.${out_name}.nc
done

echo '...Done'
