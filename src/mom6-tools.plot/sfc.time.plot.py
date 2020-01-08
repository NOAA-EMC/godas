import os, sys
file_path = '/scratch2/NCEPDEV/marineda/common/mom6-tools/mom6_tools'
sys.path.append(os.path.dirname(file_path))

from mom6_tools.MOM6grid import MOM6grid
from mom6_tools.latlon_analysis import time_mean_latlon
import matplotlib.pyplot as plt
import xarray as xr
import argparse
import datetime
import re
import warnings

def get_ocn_hours(filename,ref_date):
  ymd  = re.search(r'\d{4}_\d{2}_\d{2}', filename)
  ymdh = re.search(r'\d{4}_\d{2}_\d{2}_\d{2}', filename)

  ymd_=format(ymd.group(0))
  ymd_dform=ymd_.replace('_', "-")

  ymdh_=format(ymdh.group(0))
  hour_=ymdh_.replace(ymd_+'_', "")

  dateform=datetime.datetime.strptime(ymd_dform+' 00:00','%Y-%m-%d %H:%M').date()
  delta = dateform - ref_date
  filename_hours= delta.days*24+int(hour_)

  return filename_hours

if __name__ == "__main__":
  warnings.filterwarnings("ignore")
  class args:
    pass

  # required arg  
  parser = argparse.ArgumentParser()
  parser.add_argument('-grid', required=True, help='grid/geometry filename: ocean_geometry.nc')
  parser.add_argument('-data', nargs='*', type=str, required=True, help='diag data filenames: ocn_*.nc')
  parser.add_argument('-figs_path',help='path to save png files: ../time_mean')
  args = parser.parse_args()

  print(f'Loading grid... {args.grid}')
  print(f'Loading data... {args.data}')

  # case name
  case_name = ''

  # initial and final years for computing time mean
  nc = xr.open_mfdataset(args.data[0], decode_times=False)
  year_start=nc['time'].values
  nc = xr.open_mfdataset(args.data[len(args.data)-1], decode_times=False)
  year_end=nc['time'].values

  # set ref date and time xlabel
  ref_date='2011-10-01 00:00'
  xlabel  ='hours since '+ref_date
 
  # variables to be processed
  variables = ['SST','SSH']

  # Put your name and email address below
  author = 'Jong Kim (jong.kim@noaa.gov)'
  ######################################################

  # set args to be use in making plots
  args.infile = args.data
  args.year_start = year_start
  args.year_end = year_end
  args.case_name = case_name
  args.variables = variables
  args.xlabel = xlabel
  args.savefigs = True
  args.time_series = True
  args.filename_times = []
  args.ref_date = datetime.datetime.strptime(ref_date,'%Y-%m-%d %H:%M').date()

  # load mom6 grid
  grd = MOM6grid(args.grid)
  grd.area_t=grd.Ah

  # set data and fig file path 
  if args.figs_path is None:
     head, tail = os.path.split(args.data[0])
     save_path = str(head + '/time_mean')
     args.figs_path = save_path

  if not os.path.isdir(args.figs_path): os.makedirs(args.figs_path)

  # set external time stamp from data filename
  for filename in args.data:
    filename_hours = get_ocn_hours(filename, args.ref_date)
    args.filename_times.append(filename_hours)

  # do time mean plots
  time_mean_latlon(args,grd)

