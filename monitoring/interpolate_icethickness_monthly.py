import warnings; warnings.filterwarnings(action='ignore')
#%matplotlib inline
#for Netcdf manipulation
import xarray as xr
import re

#for array manipulation
import numpy as np
import pandas as pd
#for plotting
import cartopy.crs as ccrs
import cartopy
import cartopy.feature as cfeature
import matplotlib.pylab as plt

#for interpolation
from scipy.spatial import cKDTree
from matplotlib.gridspec import GridSpec
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter

varAttrs = {
            'heff': {'long_name': 'sea ice thickness',
                     'units': 'm'},
            'area': {'long_name': 'sea ice concentration',
                     'units': 'none'},
           }

def spatial_plot(lon, lat, var, varname='ice_thickness', regrid_plot=False, \
     title='total_icethickness', domain='global', bound=None):
    plt.clf()
    plt.figure(figsize=(10, 8))

    if ( domain == 'global' ):
        proj=ccrs.Robinson()
        lonmin=-180
        lonmax=180
        latmin=-90
        latmax=90
    if ( domain == 'north' ):
        proj=ccrs.NorthPolarStereo()
        lonmin=-180
        lonmax=180
        latmin=50
        latmax=90
    if ( domain == 'south' ):
        proj=ccrs.SouthPolarStereo()
        lonmin=-180
        lonmax=180
        latmin=-90
        latmax=-50

    ax = plt.axes(projection=proj)
    if bound is None:
        vmin = var.min()
        vmax = var.max()
    else:
        vmin = bound[0]
        vmax = bound[1]
    var=np.ma.masked_less_equal(var, 0.1)
    levels=np.linspace(vmin, vmax, 10)
    levels = [round(xx, 1) for xx in levels]
    if regrid_plot:
        obsax = ax.contourf(lon, lat, var,\
                   vmin=vmin, vmax=vmax, \
                   transform=ccrs.PlateCarree(),\
                   levels=levels,\
                   cmap='jet' )
        ax.contour(lon, lat, var,
                          levels = levels,
                          linewidths=1,
                          colors='k',
                          transform = ccrs.PlateCarree())
    else:
        obsax=plt.scatter( lon, lat, c=var, s=.1,
           cmap='jet', transform=ccrs.PlateCarree(),
            vmin=vmin, vmax=vmax)
        lon=lon.values.flatten()
        lat=lat.values.flatten()
        var=var.data.flatten()

        ax.tricontour(lon, lat, var,\
                   levels=levels,\
                   colors='k',
                   transform=ccrs.PlateCarree())
    ax.add_feature(cartopy.feature.LAND, edgecolor='black')
    ax.add_feature(cartopy.feature.LAKES, edgecolor='black')
    ax.coastlines()
    ax.set_extent([lonmin, lonmax, latmin, latmax], ccrs.PlateCarree())
    plt.colorbar(obsax, shrink=0.5) #.set_label(varname)
    plt.title(title, fontsize=14, fontweight='bold')
    plt.savefig('plots/Fig_%s_%s.png'%(domain, varname),  bbox_inches='tight', pad_inches = 0.02)

class Grid():
    def __init__(self, srcFile=None, trgFile=None):
        self.srcFile = srcFile
        self.trgFile = trgFile

    def lon_lat_to_cartesian(self, lon, lat):
        # WGS 84 reference coordinate system parameters
        A = 6378.137 # major axis [km]   
        E2 = 6.69437999014e-3 # eccentricity squared 
    
        lon_rad = np.radians(lon)
        lat_rad = np.radians(lat)
        # convert to cartesian coordinates
        r_n = A / (np.sqrt(1 - E2 * (np.sin(lat_rad) ** 2)))
        x = r_n * np.cos(lat_rad) * np.cos(lon_rad)
        y = r_n * np.cos(lat_rad) * np.sin(lon_rad)
        z = r_n * (1 - E2) * np.sin(lat_rad)
        return x,y,z

    def source_grid(self, mm=1):
        print('month', mm+1)
        source = xr.open_dataset(self.srcFile)
        self.srclat = source.variables['lat_scaler'][:]
        self.srclon = source.variables['lon_scaler'][:]
        self.ice = source.variables['heff'][:]
        self.ice= self.ice[mm]

    def target_grid(self):
        target = xr.open_dataset(self.trgFile)
        self.tglat2d=target.lat[0]
        self.tglon2d=target.lon[0]

    def kdtree_interp(self, mm=1, orig_plot=False, regrid_plot=False):
        import time
        starttime=time.time()
        self.source_grid(mm=mm)
        xs, ys, zs = self.lon_lat_to_cartesian(self.srclon.values.flatten(), self.srclat.values.flatten())
        self.target_grid()
        xt, yt, zt = self.lon_lat_to_cartesian(self.tglon2d.values.flatten(), self.tglat2d.values.flatten())
        tree = cKDTree(np.column_stack((xs, ys, zs)))
        d, inds = tree.query(np.column_stack((xt, yt, zt)), k = 1) #nterpolated 2d field
        ice_target = self.ice.values.flatten()[inds].reshape(self.tglon2d.shape)
        ice_target[ice_target>9999.]=0
        if orig_plot:
            ice=self.ice
            ice=np.ma.masked_greater_equal(ice, 9999.)
            ice[ice.mask]=0
            spatial_plot(self.srclon, self.srclat, ice, \
                 varname='max-ice-thickness_%sm_orig'%(mm), regrid_plot=False,\
                 domain='north', title='Max ice thickness %02d m'%(mm), bound=[0, 5])
        if regrid_plot:
            spatial_plot(self.tglon2d, self.tglat2d, ice_target, \
            varname='max-ice-thickness_%sm_regrid'%(mm), regrid_plot=True, \
            domain='north', title='Max ice thickness %02d m'%(mm), bound=[0, 5])
        endtime=time.time()
        print("time for interpolation: ", endtime-starttime)
        return self.tglon2d, self.tglat2d, ice_target 


def write_to_netcdf(lon, lat, data, filo, months=None, fill_value=1e20, variable='heff', attributes=None):

    from netCDF4 import Dataset, date2num
    import datetime as dt
    import numpy as np
    
    nt, nx, ny = data.shape
    # Create time
    yyyy = int( re.search('(\d{4})\.', filo).groups()[0] )
    if months is None or nt==12 :
        t = [dt.datetime(yyyy,mm,1) for mm in range(1,nt+1,1)]
    else:
        t = [dt.datetime(yyyy,mm,1) for mm in months]
        
    rootgrp = Dataset(filo, 'w')
    time = rootgrp.createDimension('time', None)
    x = rootgrp.createDimension('x', nx)
    y = rootgrp.createDimension('y', ny)

    times = rootgrp.createVariable( 'time', 'f8', ('time',) )
    lats = rootgrp.createVariable( 'latitude', 'f4', ('x','y',) )
    lons = rootgrp.createVariable( 'longitude', 'f4', ('x','y',) )
    var = rootgrp.createVariable( variable, 'f4', ('time','x','y',), fill_value=fill_value )

    rootgrp.description = 'PIOMAS sea ice thickness'
    rootgrp.created = dt.datetime.now().strftime('%Y-%m-%d %H:%M')
    rootgrp.created_by = 'A.P.Barrett <apbarret@nsidc.org>'
    rootgrp.source = 'http://psc.apl.uw.edu/research/projects/arctic-sea-ice-volume-anomaly/data/model_grid'

    times.long_name = 'time'
    times.units = 'days since 1900-01-01 00:00:00'
    times.calendar = 'gregorian'
    lats.long_name = 'latitude'
    lats.units = 'degrees_north'
    lons.long_name = 'longitude'
    lons.units = 'degrees_east'
    if attributes:
        var.long_name = attributes['long_name']
        var.units = attributes['units']

    times[:] = date2num(t, units=times.units, calendar=times.calendar)
    lons[:,:] = lon
    lats[:,:] = lat
    var[:,:,:] = np.where(np.isnan(data), fill_value, data)

    rootgrp.close()
    
    return

if __name__=="__main__":
    import os
    description = """ Ex. interpolate_icethickness_monthly.py -g gridfile
                           -s srcFile -o outputfile -m 5 6 7
                  """
    # Command line argument
    parser = ArgumentParser(
        description=description,
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '-g',
        '--grdFile',
        type=str, required=True)
    parser.add_argument(
        '-s',
        '--srcFile',
        type=str, required=True)
    parser.add_argument(
        '-o',
        '--outputfile',
        type=str, required=True)
    parser.add_argument(
        '-p',
        '--orig_plot',
        type=bool, default=False, required=False)
    parser.add_argument(
        '-r',
        '--regrid_plot',
        type=bool, default=False, required=False)
    parser.add_argument(
        '-m',
        '--month',
        help=" [start, end]",
        type=int, nargs='+', required=False)

    #from plot_ts_vol_giomas import spatial_plot
    args = parser.parse_args()
    srcFile = args.srcFile
    grid = Grid(srcFile = srcFile, trgFile=args.grdFile)
    print(srcFile)
    filo=args.outputfile
    yyyy = int( re.search('(\d{4})\.', filo).groups()[0] )
    variable='heff'
    
    if args.month is None:
        month = range(1,13)
    else:
        month = args.month

    dstData=[]
    for i in month:
        dstlon, dstlat, ice=grid.kdtree_interp(mm=i-1, orig_plot=args.orig_plot, regrid_plot=args.orig_plot)
        dstData.append(ice)
    dstData=np.array(dstData)
    write_to_netcdf(dstlon, dstlat, dstData, filo, months=month, variable=variable, attributes=varAttrs[variable])
