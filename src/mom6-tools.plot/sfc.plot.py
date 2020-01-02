import os, sys
file_path = '/scratch2/NCEPDEV/marine/Jong.Kim/mom6-tools/mom6_tools'
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
#parser.add_argument('-data', required=True)               
parser.add_argument('-data', nargs='*', type=str, required=True, help='diag data filename(s): ocn_*.nc')
args = parser.parse_args()

print(f'Loading grid... {args.grid}')
print(f'Loading data... {args.data}')

grd= MOM6grid(args.grid)
grd.area_t=grd.Ah

clim_sst=[-2,0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32]
clim_ssh=[-1.5,-1.0,-0.5,0.0,0.5,1.0,1.5,2.0]

for filename in args.data:
    nc = xr.open_mfdataset(filename , decode_times=False)
    path_ = Path(filename)
    sst_fig = str(path_.parent.joinpath(path_.stem + '_SST.png'))
    ssh_fig = str(path_.parent.joinpath(path_.stem + '_SSH.png'))

    path_ = Path(filename)
    file_sst = str(path_.parent.joinpath(path_.stem + '_sstpng'))
    file_ssh = str(path_.parent.joinpath(path_.stem + '_ssh.png'))

    title_sst='SST:'+str(path_.parent.joinpath(path_.stem))
    title_ssh='SSH:'+str(path_.parent.joinpath(path_.stem))

    xyplot(nc.SST[0,:,:].to_masked_array(),grd.geolon,grd.geolat,clim=clim_sst,title=title_sst,save=sst_fig)
    xyplot(nc.SSU[0,:,:].to_masked_array(),grd.geolon,grd.geolat,clim=clim_ssh,title=title_ssh,save=ssh_fig)
  
