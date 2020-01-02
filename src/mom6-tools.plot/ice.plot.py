import os, sys
file_path = '/scratch2/NCEPDEV/marineda/common/mom6-tools/mom6_tools'
sys.path.append(os.path.dirname(file_path))

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
args = parser.parse_args()

print(f'Loading grid... {args.grid}')
print(f'Loading data... {args.data}')
 
case_name = 'cic.socagodas.an.2011-10-01~09'
 
year_start = 1
year_end = 1
author = 'Jong Kim (jong.kim@noaa.gov)'

grd= MOM6grid(args.grid)
grd.area_t=grd.Ah

clim_hice=[0, 0.5, 1.0, 1.5, 2.0, 2.5, 3, 3.5, 4.0, 5.0, 6, 9, 12, 15]
clim_aice=[0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
clmap_=cmocean.cm.ice

for filename in args.data:
    nc = xr.open_mfdataset(filename, decode_times=False)
    hice = np.ma.masked_invalid(nc['hice'].data)
    hice_sh = np.ma.masked_where(grd.geolat > 0., hice[0,:,:])
    hice_nh = np.ma.masked_where(grd.geolat < 0., hice[0,:,:])    
    aice = np.ma.masked_invalid(nc['aice'].data)
    aice_sh = np.ma.masked_where(grd.geolat > 0., aice[0,:,:])
    aice_nh = np.ma.masked_where(grd.geolat < 0., aice[0,:,:])

    path_ = Path(filename)
    file_hice_nh = str(path_.parent.joinpath(path_.stem + '_hice_nh.png'))
    file_hice_sh = str(path_.parent.joinpath(path_.stem + '_hice_sh.png'))
    file_aice_nh = str(path_.parent.joinpath(path_.stem + '_aice_nh.png'))
    file_aice_sh = str(path_.parent.joinpath(path_.stem + '_aice_sh.png'))

    title_hice='hice:'+str(path_.parent.joinpath(path_.stem))
    title_aice='aice:'+str(path_.parent.joinpath(path_.stem))

    polarplot(hice_sh, grd, proj='SP', title=title_hice, debug=True, clim=clim_hice, colormap=clmap_,save=file_hice_sh)
    polarplot(hice_nh, grd, proj='NP', title=title_hice, debug=True, clim=clim_hice, colormap=clmap_,save=file_hice_nh)
    polarplot(aice_sh, grd, proj='SP', title=title_aice, debug=True, clim=clim_aice, colormap=clmap_,save=file_aice_sh)
    polarplot(aice_nh, grd, proj='NP', title=title_aice, debug=True, clim=clim_aice, colormap=clmap_,save=file_aice_nh)


