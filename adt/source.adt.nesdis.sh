#!/bin/bash
# download altimetry data (absolute dynamic topography) from NESDIS.

set -e
set -u

if [[ $# != 2 ]]; then
    echo "usage: $0 yyyymmdd output_path"
    exit 1
fi

function validate_url()
{
    wget --spider $1 >/dev/null 2>&1
    return $?
}


date=$1
yr=${date:0:4}
dy=$(date -d "$date" "+%j")

out_dir="$2/adt.nesdis"
source="ftp://ftp.star.nesdis.noaa.gov/pub/sod/lsa/rads/adt"

pwd=$(pwd)

d=${out_dir}/${date}
mkdir -p $d
cd $d

f=${source}/${yr}/rads_adt_*_${yr}${dy}.nc
echo $f
file_sfx=nc
if validate_url $f; then
   echo file exists at URL: $f
   wget  -r -l1 -nd -nc -np -e robots=off --no-parent -A.nc --no-check-certificate $f
else
   echo file does not exist at URL: $f
fi

cd $pwd

