#! /bin/csh -x

module load HPSS/5.0.2.5
module load wgrib2/2.0.8
module load NCO/4.7.0

setenv PATH ${PATH}:/u/Hyun-Chul.Lee/bin/Rahul.Mahajan

set sdate = $1
set edate = $2

echo $sdate $edate

#-- PRATE,UFLX,VFLX are from the f006 fcst of the run before 6 hour. 
set hprep = f006
#set hprep = $3


set rdir = /NCEPPROD/hpssprod/runhistory
set odir = /gpfs/dell2/emc/modeling/noscrub/Hyun-Chul.Lee/GFSv/Reanal
set wdir = /gpfs/dell2/emc/modeling/noscrub/Hyun-Chul.Lee/GFSv/Tmp_get

set dat = $sdate

if (! -d $wdir) mkdir -p $wdir
if (! -d $odir) mkdir -p $odir

cd $wdir

while ($dat <= $edate)
  set yy = `echo $dat | cut -c 1-4`
  set ym = `echo $dat | cut -c 1-6`
  set dd = `echo $dat | cut -c 7-8`
  set h = 0

  while ($h <= 18)

    set hh = `printf "%.2d" $h`
    echo ${dat}${hh}  

#-- set the time before 6 hour
    set dathb = `date -d "$dat $hh 6 hour ago" +%Y%m%d%H`
    set yyb = `echo $dathb | cut -c 1-4`
    set ymb = `echo $dathb | cut -c 1-6`
    set ddb = `echo $dathb | cut -c 7-8`
    set hhb = `echo $dathb | cut -c 9-10`
    set datb = ${ymb}${ddb}

    echo ${rdir}/rh${yy}/${ym}/${dat}/com_gfs_prod_gdas.${dat}_${hh}.gdas_flux.tar 
    htar -xvf ${rdir}/rh${yy}/${ym}/${dat}/com_gfs_prod_gdas.${dat}_${hh}.gdas_flux.tar ./gdas.${dat}/${hh}/atmos/gdas.t${hh}z.sfluxgrbf000.grib2
    htar -xvf ${rdir}/rh${yyb}/${ymb}/${datb}/com_gfs_prod_gdas.${datb}_${hhb}.gdas_flux.tar ./gdas.${datb}/${hhb}/atmos/gdas.t${hhb}z.sfluxgrb${hprep}.grib2
    htar -xvf ${rdir}/rh${yy}/${ym}/${dat}/com_gfs_prod_gdas.${dat}_${hh}.gdas_nc.tar ./gdas.${dat}/${hh}/atmos/gdas.t${hh}z.atmf000.nc
    if (-f ./gdas.${dat}/${hh}/atmos/gdas.t${hh}z.sfluxgrbf000.grib2) then
      echo ./gdas.${dat}/${hh}/atmos/gdas.t${hh}z.sfluxgrbf000.grib2 ./gdas.${datb}/${hhb}/atmos/gdas.t${hhb}z.sfluxgrb${hprep}.grib2
      wgrib2 ./gdas.${datb}/${hhb}/atmos/gdas.t${hhb}z.sfluxgrb${hprep}.grib2 -s | egrep ':PRATE:|:UFLX:|:VFLX:|:NBDSF:|:NDDSF:|:VBDSF:|:VDDSF:' | wgrib2 -i ./gdas.${datb}/${hhb}/atmos/gdas.t${hhb}z.sfluxgrb${hprep}.grib2 -grib sfluxgrb${hprep}.puvflx.grib2
      mv ./gdas.${dat}/${hh}/atmos/gdas.t${hh}z.sfluxgrbf000.grib2 ${odir}/gfs.${dat}.t${hh}z.sfcanl.grib2
      mv sfluxgrb${hprep}.puvflx.grib2 ${odir}/gfs.${dat}.t${hh}z.puvflx.grib2
      ncks -h -M -m -O -C -d pfull,126 -v delz ./gdas.${dat}/${hh}/atmos/gdas.t${hh}z.atmf000.nc gdas.t${hh}z.atmf000.delz1.nc
      mv gdas.t${hh}z.atmf000.delz1.nc ${odir}/gfs.${dat}.t${hh}z.atmf000.delz1.nc  

    else 
      htar -xvf ${rdir}/rh${yy}/${ym}/${dat}/com.gdas_prod_gdas.${dat}_${hh}.gdas_flux.tar ./gdas.${dat}/${hh}/gdas.t${hh}z.sfluxgrbf000.grib2
      htar -xvf ${rdir}/rh${yyb}/${ymb}/${datb}/com.gdas_prod_gdas.${datb}_${hhb}.gdas_flux.tar ./gdas.${datb}/${hhb}/gdas.t${hhb}z.sfluxgrb${hprep}.grib2
      htar -xvf ${rdir}/rh${yy}/${ym}/${dat}/com.gdas_prod_gdas.${dat}_${hh}.gdas_nc.tar ./gdas.${dat}/${hh}/gdas.t${hh}z.atmf000.nc
      echo ./gdas.${dat}/${hh}/gdas.t${hh}z.sfluxgrbf000.grib2 ./gdas.${datb}/${hhb}/gdas.t${hhb}z.sfluxgrb${hprep}.grib2
      wgrib2 ./gdas.${datb}/${hhb}/gdas.t${hhb}z.sfluxgrb${hprep}.grib2 -s | egrep ':PRATE:|:UFLX:|:VFLX:|:NBDSF:|:NDDSF:|:VBDSF:|:VDDSF:' | wgrib2 -i ./gdas.${datb}/${hhb}/gdas.t${hhb}z.sfluxgrb${hprep}.grib2 -grib sfluxgrb${hprep}.puvflx.grib2
      mv ./gdas.${dat}/${hh}/gdas.t${hh}z.sfluxgrbf000.grib2 ${odir}/gfs.${dat}.t${hh}z.sfcanl.grib2
      mv sfluxgrb${hprep}.puvflx.grib2 ${odir}/gfs.${dat}.t${hh}z.puvflx.grib2
      ncks -h -M -m -O -C -d pfull,126 -v delz ./gdas.${dat}/${hh}/gdas.t${hh}z.atmf000.nc gfs.t${hh}z.atmf000.delz1.nc
      mv gdas.t${hh}z.atmf000.delz1.nc ${odir}/gfs.${dat}.t${hh}z.atmf000.delz1.nc  
    endif
    if (! -f ${odir}/gfs.${dat}.t${hh}z.sfcanl.grib2) then
      echo "file cannot find :" gfs.${dat}.t${hh}z.sfcanl.grib2
      exit 999
    endif

    @ h = $h + 6

  end #while ($h <= 18)

#  /bin/rm -r ${wdir}/gfs.${dat}
  set dat = `date -d "$dat 1 day" +%Y%m%d` 

end #while ($dat <= $edate)



