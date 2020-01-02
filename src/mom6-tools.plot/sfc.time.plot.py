import os, sys
file_path = '/scratch2/NCEPDEV/marine/Jong.Kim/mom6-tools/mom6_tools'
sys.path.append(os.path.dirname(file_path))

from mom6_tools.MOM6grid import MOM6grid
from mom6_tools.latlon_analysis import time_mean_latlon
import matplotlib.pyplot as plt
import argparse
import warnings
warnings.filterwarnings("ignore")
class args:
  pass

# required arg                                                                                                                      
parser = argparse.ArgumentParser()
parser.add_argument('-grid', required=True)
parser.add_argument('-data', nargs='*', type=str, required=True)
args = parser.parse_args()

print(f'Loading grid... {args.grid}')
print(f'Loading data... {args.data}')

# case name
case_name = 'Test_data'

# initial and final years for computing time mean
year_start = 3
year_end = 195
xlabel='hours since 2012-01-01 00'

# variables to be processed
variables = ['SST','SSH']

# Put your name and email address below
author = 'Jong Kim (jong.kim@noaa.gov)'
######################################################

args.infile = args.data
args.year_start = year_start
args.year_end = year_end
args.case_name = case_name
args.variables = variables
args.xlabel = xlabel
args.savefigs = True
args.time_series = True

# load mom6 grid
grd = MOM6grid(args.grid)
grd.area_t=grd.Ah
# plot time averages. If variables is NOT specified, all 2D variables will be plotted.
time_mean_latlon(args,grd)
