0-1. This directory contains python plotting scripts based on mom6-tools. Note that scripts run with local cartopy shapefiles in /scratch2/NCEPDEV/marineda/common/cartopy.

0-2. Python scripts require two input arguments: grid and data file names. Multiple data files can be used with wildcard (*) input for data file names. As of now (01/07/2020), diag_table files are not fully updated for variables needed in mom6-tools modules yet. For the time being, users can utilize ocean_geometry.nc in /scratch2/NCEPDEV/marineda/common. Test runs for plotting examples are:

python ice.plot.py -grid ocean_geometry.nc -data cic.socagodas.an.2011-10-*T12:00:00Z.nc 

-grid file: geometry input file should contain geolon and geolat variables.

-data file: aice and hice variables are used to make hemispheric plots.

python sfc.plot.py -grid ocean_geometry.nc -data ocn_2012_01_*_03.nc

-grid file: geometry input file should contain geolon and geolat variables.

-data file: SSH and SST variables are used to make surface plots.

python sfc.time.plot.py -grid ocean_geometry.nc -data ocn_2012_01_*_03.nc

-grid file: geometry input file should contain geolon and geolat variables.

-data file: SSH and SST variables are used to make average surface and time-varying statistics plots.
