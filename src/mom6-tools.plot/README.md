0-1. This directory contains python plotting scripts based on mom6-tools. Note that scripts run with local cartopy shapefiles in /scratch2/NCEPDEV/marineda/common/cartopy.

0-2. Python scripts require two input arguments: grid and data file names. Multiple data files can be used with wildcard (*) input for data file names. As of now (01/07/2020), diag_table files are not fully updated for variables needed in mom6-tools modules yet. For the time being, users can utilize ocean_geometry.nc in /scratch2/NCEPDEV/marineda/common. Test runs for plotting examples are:

python ice.plot.py -grid ocean_geometry.nc -data cic.socagodas.an.2011-10-*T12:00:00Z.nc -figs_path ./fcst -var hice aice

-grid file: geometry input file should contain geolon and geolat variables.

-data file: aice and hice variables are used to make hemispheric plots.

-figs_path (optional): path to save png files (e.g., -figs_path ./fcst)

-var (optional): variable names to plot (e.g., -var hice aice or -var hi_h aice_h)

python sfc.plot.py -grid ocean_geometry.nc -data ocn_2012_01_*_03.nc -figs_path ./fcst

-grid file: geometry input file should contain geolon and geolat variables.

-data file: SSH and SST variables are used to make surface plots.

-figs_path (optional): path to save png files (e.g., -figs_path ./fcst)

python sfc.time.plot.py -grid ocean_geometry.nc -data ocn_2012_01_*_03.nc -figs_path ./time_mean

-grid file: geometry input file should contain geolon and geolat variables.

-data file: SSH and SST variables are used to make average surface and time-varying statistics plots.

-figs_path (optional): path to save png files (e.g., -figs_path ./fcst)

By default, scripts save png figures along with data files: time_mean sub-directory for time-average/time-series figures.