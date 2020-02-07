import os, sys
file_path = '/scratch2/NCEPDEV/marineda/common/mom6-tools/mom6_tools'
sys.path.append(os.path.dirname(file_path))

from pathlib import Path
from mom6_tools.MOM6grid import MOM6grid
from mom6_tools.latlon_analysis import time_mean_latlon
from mom6_tools.m6plot import xyplot
import matplotlib.pyplot as plt
import warnings
import xarray as xr
import argparse
class args:
  pass

# required arg
parser = argparse.ArgumentParser()
parser.add_argument('-grid', required=True, help='grid/geometry filename: ocean_geometry.nc')
parser.add_argument('-data', nargs='*', type=str, required=True, help='diag data filename(s): ocn_*.nc')
parser.add_argument('-figs_path',help='path to save png files: ./fcst')
args = parser.parse_args()

print(f'Loading grid... {args.grid}')
print(f'Loading data... {args.data}')

if args.figs_path is None:
    print('Creating figures in -data directory ...')
else:
    if not os.path.isdir(args.figs_path): os.makedirs(args.figs_path)

grd= MOM6grid(args.grid)

clim_sst=[-2,0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32]
clim_ssh=[-1.5,-1.0,-0.5,0.0,0.5,1.0,1.5,2.0]
clim_sss=[30,31,32,33,34,35,36,37,38,39,40]

for filename in args.data:
    nc = xr.open_mfdataset(filename , decode_times=False)
    path_ = Path(filename)
    name_ = Path(filename).name
    if args.figs_path is None:
      sst_fig = str(path_.parent.joinpath(path_.stem + '_SST.png'))
      ssh_fig = str(path_.parent.joinpath(path_.stem + '_SSH.png'))
      sss_fig = str(path_.parent.joinpath(path_.stem + '_SSS.png'))

    else:
      sst_fig = str(args.figs_path+'/'+path_.stem + '_SST.png')
      ssh_fig = str(args.figs_path+'/'+path_.stem + '_SSH.png')
      sss_fig = str(args.figs_path+'/'+path_.stem + '_SSS.png')

    title_sst='SST:'+str(name_)
    title_ssh='SSH:'+str(name_)
    title_sss='SSS:'+str(name_)

    xyplot(nc.SST[0,:,:].to_masked_array(),grd.geolon,grd.geolat,clim=clim_sst,title=title_sst,save=sst_fig)
    xyplot(nc.SSH[0,:,:].to_masked_array(),grd.geolon,grd.geolat,clim=clim_ssh,title=title_ssh,save=ssh_fig)
    xyplot(nc.SSS[0,:,:].to_masked_array(),grd.geolon,grd.geolat,clim=clim_sss,title=title_sss,save=sss_fig)
   
