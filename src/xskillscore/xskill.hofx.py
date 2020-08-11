import xarray as xr
import pandas as pd
import numpy as np
from scipy.stats import norm
import xskillscore as xs
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-data', nargs='*', type=str, required=True, help='input data file name: l2.f286._*.nc')
args = parser.parse_args()

# read data file(s)-------------------------------------------------------
filename = args.data
nc       = xr.open_mfdataset(filename, decode_times=False)
lat      = np.ma.masked_invalid(nc['latitude@MetaData'].data)
lon      = np.ma.masked_invalid(nc['longitude@MetaData'].data)
#obstime = np.ma.masked_invalid(nc['datetime@MetaData'].data)                                                                         
record  = np.ma.masked_invalid(nc['record_number@MetaData'].data)

obs_in= np.ma.masked_invalid(nc['sea_ice_area_fraction@ObsValue'].data)
qc    = np.ma.masked_invalid(nc['sea_ice_area_fraction@EffectiveQC0'].data)
omg   = np.ma.masked_invalid(nc['sea_ice_area_fraction@ombg'].data)
oma   = np.ma.masked_invalid(nc['sea_ice_area_fraction@oman'].data)
bkg   = obs_in - omg
ana   = obs_in - oma

# set obs and fct arrays -------------------------------------------------
obs = xr.DataArray(
    obs_in,
    coords=[
        record
    ],
    dims=["nlocs"],
)
fct = obs.copy()
fct.values = bkg

### Deterministic metrics
# Pearson's correlation coefficient
r = xs.pearson_r(obs, fct, "nlocs")

# 2-tailed p-value of Pearson's correlation coefficient                                                                               
#jkim r_p_value = xs.pearson_r_p_value(obs, fct, "nlocs")

# Spearman's correlation coefficient                                                                                                  
rs = xs.spearman_r(obs, fct, "nlocs")

# 2-tailed p-value associated with Spearman's correlation coefficient                                                                 
#jkim rs_p_value = xs.spearman_r_p_value(obs, fct, "nlocs")

# Root Mean Squared Error                                                                                                             
rmse = xs.rmse(obs, fct, "nlocs")

# Mean Squared Error                                                                                                                  
mse = xs.mse(obs, fct, "nlocs")

# Mean Absolute Error                                                                                                                 
mae = xs.mae(obs, fct, "nlocs")

# Median Absolute Error                                                                                                               
median_absolute_error = xs.median_absolute_error(obs, fct, "nlocs")

# Mean Absolute Percentage Error                                                                                                      
mape = xs.mape(obs, fct, "nlocs")

# Symmetric Mean Absolute Percentage Error                                                                                            
#jkim smape = xs.smape(obs, fct, "nlocs")

# You can also specify multiple axes for deterministic metrics:                                                                       
# Apply Pearson's correlation coefficient                                                                                             
# over the latitude and longitude dimension                                                                                           
#jkim r = xs.pearson_r(obs, fct, ["lat", "lon"])

print(r,rs,rmse)
