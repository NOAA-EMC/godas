1-1. This directory contains python plotting scripts based mom6-tools. Local cartopy shapefiles are needed in user's own home/.local directory: if .local/share/cartopy directory does not exist, create one: /home/First.LastNames/.local/share/cartopy/shapefiles/natural_earth/physical

mkdir -p /home/First.LastNames/.local/share/cartopy/shapefiles/natural_earth/physical
cp /home/Jong.Kim/.local/share/cartopy/shapefiles/natural_earth/physical/* /home/First.LastNames/.local/share/cartopy/shapefiles/natural_earth/physical/*

1-2. Basic use of each python script require two input arguments: grid and data file names. Multiple data files can be used with wildcard (*). Examples are:

python -grid ocean_geometry.nc -data cic.socagodas.an.2011-10-*T12:00:00Z.nc 

-grid file: geolon and geolat are expected in geometry input file.

-data file: aice and hice variables are used to make hemispheric plots.

python sfc.plot.py -grid ocean_geometry.nc -data ocn_2012_01_*_03.nc

-grid file: geolon and geolat are expected in geometry input file.

-data file: SSH and SST variables are used to make surface plots.

python sfc.time.py -grid ocean_geometry.nc -data ocn_2012_01_*_03.nc

-grid file: geolon and geolat are expected in geometry input file.

-data file: SSH and SST variables are used to make average surface and time-varying statistics plots.




