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

def date_parse(filename):
  ymdh = re.search(r'\d{4}_\d{2}_\d{2}_\d{2}', filename)
  if not (ymdh is None):
    ymdh_= format(ymdh.group(0))
    ymd_dform = ymdh_.replace('_', "-")
    hr = ymd_dform[-2:]
    ymd_dform = ymd_dform[:-3]
    tdate = datetime.datetime.strptime(ymd_dform+' '+hr+':00','%Y-%m-%d %H:%M')
    return tdate

  ymdh = re.search(r'\d{4}_\d{2}_\d{2}', filename)
  if not (ymdh is None):
    ymdh_=format(ymdh.group(0))
    ymd_dform=ymdh_.replace('_', "-")
    tdate=datetime.datetime.strptime(ymd_dform+' 00:00','%Y-%m-%d %H:%M')
    return tdate

  ymdh = re.search(r'\d{4}-\d{2}-\d{2}-\d{2}', filename)
  if not (ymdh is None):
    ymdh_= format(ymdh.group(0))
    hr = ymdh_[-2:]
    ymdh_ = ymd_dform[:-3]
    tdate = datetime.datetime.strptime(ymdh_+' '+hr+':00','%Y-%m-%d %H:%M')
    return tdate

  ymdh = re.search(r'\d{4}-\d{2}-\d{2}', filename)
  if not (ymdh is None):
    ymdh_=format(ymdh.group(0))
    tdate=datetime.datetime.strptime(ymdh_+' 00:00','%Y-%m-%d %H:%M')
    return tdate

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

#  print(parse( args.data[0], tzinfo=tzutc() ))
#  parse('2018-04-29T17:45:25Z')
  # case name
  case_name = ''

  # initial and final years for computing time mean
  t_start = date_parse(args.data[0])
  t_end   = date_parse(args.data[len(args.data)-1])

  # set ref date and time xlabel
  xlabel   ='days since '+str(t_start.strftime('%Y-%m-%d %H'))
 
  # variables to be processed
  variables = ['SST','SSH']

  # Put your name and email address below
  author = 'Jong Kim (jong.kim@noaa.gov)'
  ######################################################

  # set args to be use in making plots
  args.infile = args.data
  args.year_start = 0.
  args.year_end = (t_end-t_start).total_seconds()/3600/24
  args.case_name = case_name
  args.variables = variables
  args.xlabel = xlabel
  args.savefigs = True
  args.time_series = True
  args.filename_times = []
  args.file_ext = str(t_start.strftime('%Y-%m-%d_%H')+'-'+t_end.strftime('%Y-%m-%d_%H'))

  # load mom6 grid
  grd = MOM6grid(args.grid)

  # set data and fig file path 
  if args.figs_path is None:
     head, tail = os.path.split(args.data[0])
     save_path = str(head + '/time_mean')
     args.figs_path = save_path

  if not os.path.isdir(args.figs_path): os.makedirs(args.figs_path)

  # set external time stamp from data filename
  for filename in args.data:
    t_time = date_parse(filename)
    args.filename_times.append((t_time-t_start).total_seconds()/3600/24)

  # do time mean plots
  time_mean_latlon(args,grd)

