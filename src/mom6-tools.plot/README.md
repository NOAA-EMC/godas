0-1. This directory contains python plotting scripts based on mom6-tools. Note that scripts run with local cartopy shapefiles in /scratch2/NCEPDEV/marineda/common/cartopy.

0-2. offline.plot.sh can be used to generate post processing plots. This script can be copied to any local directory and run with input path of each experiment case (or PROJECT_DIR/WORKFLOW_NAME):

offline.plot.sh path_for_case1 path_for_case2

If multiple case path inputs are given, the script will go through loops to create figure directories for each run of cases. In $RUNCDATE/Figures, sea ice fraction, SST, SSH, and time_mean figures will be created. Detail instruction to run each plotting python script is given below:

0-2-1. Python plotting scripts of mom6-tools require two input arguments: grid and data file names. Multiple data files can be used with wildcard (*) input for data file names. We keep -grid argument to allow fexibility of using any source of geolon/geolat information. If diagnostic data files contain geolon/geolat variables, a diagnostic data file name can be given to -grid argument. Test runs for plotting examples are:

* python ice.plot.py -grid ocean_geometry.nc -data cic.socagodas.an.2011-10-*T12:00:00Z.nc -figs_path ./fcst -var hice aice 

-grid file: geometry input file should contain geolon and geolat variables.

-data file: aice and hice variables are used to make hemispheric plots.

-figs_path (optional): path to save png files (e.g., -figs_path ./fcst)

-var (optional): variable names to plot (e.g., -var hice aice or -var hi_h aice_h)

* python sfc.plot.py -grid ocean_geometry.nc -data ocn_2012_01_*_03.nc -figs_path ./fcst*

-grid file: geometry input file should contain geolon and geolat variables.

-data file: SSH and SST variables are used to make surface plots.

-figs_path (optional): path to save png files (e.g., -figs_path ./fcst)

* python sfc.time.plot.py -grid ocean_geometry.nc -data ocn_2012_01_*_03.nc -figs_path ./time_mean*

-grid file: geometry input file should contain geolon and geolat variables.

-data file: SSH and SST variables are used to make average surface and time-varying statistics plots.

-figs_path (optional): path to save png files (e.g., -figs_path ./fcst)

* python x(or y)z.plot.py -grid ocean_geometry.nc -data ocn_2012_01_*_03.nc -figs_path ./time_mean*

-grid file: geometry input file should contain geolon and geolat variables.

-data file: temp and so variables are used to make cross-sections at specific longitudes and latitudes,
and down to 500m depth, these options are hardcoded in the scripts.

-figs_path (optional): path to save png files (e.g., -figs_path ./fcst)


If -fig_path is not given, scripts will save png figures along with data files.


