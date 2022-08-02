#! /bin/bash


if [ $# -eq 0 ]; then
  echo "sdate and edate should be set "
  exit 99
elif [ $# -eq 1 ]; then
  sdate=$1
  edate=$1
else 
  sdate=$1
  edate=$2
fi

module use /work/noaa/da/Hyun-Chul.Lee/modulefiles
module load anaconda

wdir="/work/noaa/marine/Hyun-Chul.Lee/emc4"

do_plot=1
do_ombg=1
do_tar=0

fcstlen=24

if [ $do_plot -eq 1 ]; then
for v in bkg incr; do
  bash soca_plotfield.sh -x emc4 -v $v -s $sdate -e $edate -p $wdir -l $fcstlen
done
  if [ $do_ombg -eq 1 ];then
    bash godas_plotobs.sh -x emc4 -v obs_out -s $sdate -e $edate -p $wdir -l $fcstlen
  fi
fi

if [ $do_tar -eq 1 ]; then
  wdate=$sdate
  while [ $wdate -le $edate ]; do
    for v in bkg incr ombg; do
      cd ${wdir}/${wdate}/${v}
      tar cvf emc4.${v}.${wdate}.png.tar *.png
      if [ $v != "bkg" ]; then
        mv emc4.${v}.${wdate}.png.tar  ${wdir}/${wdate}/bkg/. 
      fi
    done
    echo $wdate
    wdate=`date -d "$wdate 1 day" +%Y%m%d`
  done
fi
