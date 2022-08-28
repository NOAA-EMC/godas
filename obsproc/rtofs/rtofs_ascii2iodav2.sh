#!/bin/bash

#YMD=20201026
#plat=metop
#./rtofs_ascii2iodav2.py -i sst.txt -v sea_surface_temperature -o ./sst_${plat}_${YMD}.nc

#YMD=20201018
#plat=ssh
#./rtofs_ascii2iodav2.py -i ssh.txt -v absolute_dynamic_topography -o ./adt_${plat}_${YMD}.nc

#YMD=20210131
#plat=salinity
#./rtofs_ascii2iodav2.py -i sss.txt -v sea_surface_salinity -o ./sss_${plat}_${YMD}.nc

YMD=20201024
plat=profile
./rtofs_ascii2iodav2.py -i profile.txt -v sea_water_temperature -o ./insitu_${plat}_${YMD}.nc
