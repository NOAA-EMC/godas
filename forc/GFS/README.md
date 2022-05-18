## Description

* This package generates DATM input data for the forcing fluxes at the sea surface from the NCEP operational GFSv16 outputs.

## Inputs of conversion in conv_gfs2datm_long_beta4.f

* INPUT variables : the output of GFSv16,

    ./gdas.${dat}/${hh}/atmos/gdas.t${hh}z.sfluxgrbf000.grib2
    ==> longitude, latitude, time, DLWRF_surface, ULWRF_surface, DSWRF_surface, UFLX_surface, VFLX_surface, SHTFL_surface,
      LHTFL_surface, PRATE_surface, UGRD_10maboveground, VGRD_10maboveground, PRES_surface, TMP_1hybridlevel, 
      SPFH_1hybridlevel, UGRD_1hybridlevel, VGRD_1hybridlevel, SPFH_2maboveground, TMP_2maboveground, LAND_surface, 
      delz, PRATE_surface, pres_hyblev1, precp, fprecp, ICEC_surface

* Input data are from the GFSv16 outs of ./gdas.${dat}/${hh}/atmos/gdas.t${hh}z.sfluxgrbf000.grib2, initial analysis fields, 
  except following missing variables in the initial file.

./gdas.${datb}/${hhb}/atmos/gdas.t${hhb}z.sfluxgrb${hprep}.grib2 :: 6 hour forecast fields at the analysis time
      ==> PRATE_surface, UFLX_surface, VFLX_surface

./gdas.${dat}/${hh}/atmos/gdas.t${hh}z.atmf000.nc  : 
     ==> delz

## OUTPUT of conversion in conv_gfs2datm_long_beta4.f
* OUTPUT variables for DATM
  ==> lat, lon, time, DLWRF, ULWRF, DSWRF, vbdsf_ave, vddsf_ave, nbdsf_ave, nddsf_ave, dusfc, dvsfc, shtfl_ave, lhtfl_ave, 
          totprcp_ave, u10m, v10m, hgt_hyblev1, psurf, tmp_hyblev1, spfh_hyblev1, ugrd_hyblev1, vgrd_hyblev1, q2m, t2m, 
          slmsksfc, pres_hyblev1, precp, fprecp, icecsfc

## Additional conversions
* vbdsf_ave, vddsf_ave, nbdsf_ave, nddsf_ave are estimated from DSWRF_surface, multiplied by 0.285 (vbdsf_ave, addsf_ave) and 0.215 (nbdsf_ave, nddsf_ave). 

* hgt_hyblev1 are obtained by delz with inverse direction of hight : -1* delz

* precp and fprecp are estimated by the thresh hold of TMP_2maboveground by -15oC.

* pres_hyblev1 are calculated from delz, TMP_1HYBRIDLEVEL, PRES_SURFACE.

* In the GFS_DATM, there is no bulk formula caluration


## Code and scripts
* comp_f77_code.csh : compilation code
* get_gfs_beta4_gdas.csh : Import input files from HPSS and merge variables into a file
* conv_gfs2datm_long_beta4.f : convert input file to DATM output
* conv_gfs2datm.fort_beta4.csh : script for conversion
* run_gfs2datm_inter.csh : wrap script for getting and converting

## Instruction of conversion
 - Compile the code by comp_f77_code.csh
 - Set configurations in run_gfs2datm_inter.csh
 - Run the script : csh run_gfs2datm_inter.csh
 - Check the output with /work/noaa/ng-godas/marineda/DATM_INPUT/GFS/ in Orion


### Issue(s) addressed

Document the code that generates the forcing :
https://github.com/NOAA-EMC/godas/issues/276



## Testing
The validation of the GFS_DATM from this package has been done by the comparisons of CFSR_DATM/GEFS_DATM in the same periods.


## Dependencies

Forcing of ng-godas, and the mediator in UFS

