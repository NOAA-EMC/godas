import os, sys
from pathlib import Path
from mom6_tools.MOM6grid import MOM6grid
from mom6_tools.m6plot import polarplot
import numpy as np
import matplotlib.pyplot as plt
import warnings
import xarray as xr
import argparse
import cmocean
import cartopy.crs as ccrs
import cartopy.feature

# required arg
parser = argparse.ArgumentParser()
parser.add_argument('-grid', required=True, help='grid/geometry filename: ocean_geometry.nc')
parser.add_argument('-data', nargs='*', type=str, required=True, help='diag data filename(s): ocn_*.nc')
parser.add_argument('-figs_path',help='path to save png files: ./history')
parser.add_argument('-var',nargs='*',help='variable names to plot: hice aice or hi_h aice_h')
args = parser.parse_args()

print(f'Loading grid... {args.grid}')
print(f'Loading data... {args.data}')

if args.figs_path is None:
    print('Creating figures in -data directory ...')
else:
    if not os.path.isdir(args.figs_path): os.makedirs(args.figs_path)

case_name = ''
 
year_start = 1
year_end = 1
author = 'Jong Kim (jong.kim@noaa.gov)'

clim_hice=[0, 0.5, 1.0, 1.5, 2.0, 2.5, 3, 3.5, 4.0, 5.0, 6, 9, 12, 15]
clim_aice=[0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]

if args.var is None:
    vars_ = ['hice', 'aice']
else:
    vars_ = args.var

grd= MOM6grid(args.grid)

clmap_=cmocean.cm.ice

for filename in args.data:
    nc = xr.open_mfdataset(filename, decode_times=False)
    for var in vars_:
        ice = np.ma.masked_invalid(nc[var].data)
        ice_sh = np.ma.masked_where(grd.geolat > 0., ice[0,:,:])
        ice_nh = np.ma.masked_where(grd.geolat < 0., ice[0,:,:])    

        path_ = Path(filename)
        name_ = Path(filename).name
        if args.figs_path is None:
            file_ice_nh = str(path_.parent.joinpath(path_.stem + '_'+var+'_nh.png'))
            file_ice_sh = str(path_.parent.joinpath(path_.stem + '_'+var+'_sh.png'))
        else:
            file_ice_nh = str(args.figs_path+'/'+path_.stem + '_'+var+'_nh.png')
            file_ice_sh = str(args.figs_path+'/'+path_.stem + '_'+var+'_sh.png')

        title_ice=var+':'+str(name_)

        if var == 'hice' or var == 'hi_h': clim_ = clim_hice
        if var == 'aice' or var == 'aice_h': clim_ = clim_aice

        polarplot(ice_sh, grd, proj='SP', title=title_ice, debug=True, clim=clim_, colormap=clmap_,save=file_ice_sh)
        polarplot(ice_nh, grd, proj='NP', title=title_ice, debug=True, clim=clim_, colormap=clmap_,save=file_ice_nh)


