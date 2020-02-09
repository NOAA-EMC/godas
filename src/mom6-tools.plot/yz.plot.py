import os, sys
file_path = '/scratch2/NCEPDEV/marineda/common/mom6-tools/mom6_tools'
sys.path.append(os.path.dirname(file_path))

from pathlib import Path
from mom6_tools.MOM6grid import MOM6grid
from mom6_tools.latlon_analysis import time_mean_latlon
from mom6_tools.m6plot import xyplot, yzplot
from plot_func import SOCAgrd_Lon
import matplotlib.pyplot as plt
import warnings
import xarray as xr
import argparse
import numpy as np

class args:
  pass

# required arg
parser = argparse.ArgumentParser()
parser.add_argument('-grid', required=True, help='grid/geometry filename: ocean_geometry.nc')
parser.add_argument('-data', nargs='*', type=str, required=True, help='diag data filename(s): ocn_*.nc')
parser.add_argument('-figs_path',help='path to save png files: ./fcst')
args = parser.parse_args()

#print(f'Loading grid... {args.grid}')
#print(f'Loading data... {args.data}')

if args.figs_path is None:
    print('Creating figures in -data directory ...')
else:
    if not os.path.isdir(args.figs_path): os.makedirs(args.figs_path)

grd= MOM6grid(args.grid)

clim_sst=[-2,0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32]
clim_ssh=[-1.5,-1.0,-0.5,0.0,0.5,1.0,1.5,2.0]
clim_sss=[30,31,32,33,34,35,36,37,38,39,40]

depth_max=500

cross_location_longitude = [ -155, -125, -35, -25, 165, 90, 60] 
for filename in args.data:
    for crs_loc_lon in cross_location_longitude:
        crs_loc_lon_adj = SOCAgrd_Lon (crs_loc_lon)
        print ("Cross Location Longitude=" + str(crs_loc_lon_adj))
        xh_cross = np.argmin(np.abs(grd.xh-crs_loc_lon_adj))
        nc = xr.open_mfdataset(filename , decode_times=False)
        path_ = Path(filename)
        name_ = Path(filename).name
        if crs_loc_lon < 0:
           FigFileName = str(abs(crs_loc_lon)) + 'W'
        else:
           FigFileName = str(abs(crs_loc_lon)) + 'E'

        if args.figs_path is None:
           temp_fig = str(args.figs_path+'/'+path_.stem + '_temp_' + FigFileName + '.png')
           title_cross_temp='Potential temp (degC at ' + FigFileName + '):' +str(name_)
           sal_fig = str(args.figs_path+'/'+path_.stem + '_sal_' + FigFileName + '.png')
           title_cross_sal='Sea Water Salinity (psu at ' + FigFileName + '):' +str(name_)

        else:
           temp_fig = str(args.figs_path+'/'+path_.stem + '_temp_' + FigFileName + '.png')
           title_cross_temp='Potential temp (degC at ' + FigFileName + '):' +str(name_)
           sal_fig = str(args.figs_path+'/'+path_.stem + '_sal_' + FigFileName + '.png')
           title_cross_sal='Sea Water Salinity (psu at ' + FigFileName + '):' +str(name_)

#TODO: Make the depth selection elegant
        ind_depth=np.where(nc.z_l<=depth_max)

        yzplot(nc.temp[0,np.min(ind_depth):np.max(ind_depth)+1,:,xh_cross].to_masked_array(), grd.yh, -grd.z_l[ind_depth], plotype='contourf', clim=clim_sst,title=title_cross_temp,save=temp_fig)
        
        yzplot(nc.so[0,np.min(ind_depth):np.max(ind_depth)+1,:,xh_cross].to_masked_array(), grd.yh, -grd.z_l[ind_depth], plotype='contourf', clim=clim_sss,title=title_cross_sal,save=sal_fig)

        plt.close('all')
