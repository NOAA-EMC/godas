import warnings; warnings.filterwarnings(action='ignore')
#%matplotlib inline
#for Netcdf manipulation
import xarray as xr

#for array manipulation
import numpy as np
import pandas as pd

#for plotting
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.pylab as plt

#for interpolation
from scipy.spatial import cKDTree
from matplotlib.gridspec import GridSpec


def plot_background(ax):
    ax.set_extent([-82,-73,45,49])
    ax.coastlines(resolution='110m');
    ax.add_feature(cfeature.OCEAN.with_scale('50m'))      
    ax.add_feature(cfeature.LAND.with_scale('50m'))       
    ax.add_feature(cfeature.LAKES.with_scale('50m'))     
    ax.add_feature(cfeature.BORDERS.with_scale('50m'))    
    ax.add_feature(cfeature.RIVERS.with_scale('50m'))    
    coast = cfeature.NaturalEarthFeature(category='physical', scale='10m',    
                        facecolor='none', name='coastline')
    ax.add_feature(coast, edgecolor='black')
    
    states_provinces = cfeature.NaturalEarthFeature(
        category='cultural',
        name='admin_1_states_provinces_lines',
        scale='10m',
        facecolor='none')
    ax.add_feature(states_provinces, edgecolor='gray')
   
    return ax

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

    def source_grid(self):
        source = xr.open_dataset(self.srcFile)
        self.srclat = source.variables['lat_scaler'][:]
        self.srclon = source.variables['lon_scaler'][:]
        self.ice = source.variables['heff'][:]
        self.ice= self.ice[1]
        #self.ice= np.max(self.ice, axis=0)
        #self.ice = np.ma.masked_greater_equal(self.ice, 9999.)
        print(self.srclat.shape)

    def target_grid(self):
        target = xr.open_dataset(self.trgFile)
        self.tglat2d=target.lat[0]
        self.tglon2d=target.lon[0]
        print(self.tglat2d.shape)

    def kdtree_interp(self):
        import time
        starttime=time.time()
        self.source_grid()
        xs, ys, zs = self.lon_lat_to_cartesian(self.srclon.values.flatten(), self.srclat.values.flatten())
        self.target_grid()
        xt, yt, zt = self.lon_lat_to_cartesian(self.tglon2d.values.flatten(), self.tglat2d.values.flatten())
        tree = cKDTree(np.column_stack((xs, ys, zs)))
        d, inds = tree.query(np.column_stack((xt, yt, zt)), k = 1) #nterpolated 2d field
        #self.ice[self.ice.mask]=0
        #ice = self.ice.data[0]
        #print(ice.shape)
        ice_target = self.ice.values.flatten()[inds].reshape(self.tglon2d.shape)
        ice_target = np.ma.masked_greater_equal(ice_target, 9999.)
        endtime=time.time()
        print("time for interpolation: ", endtime-starttime)
        return self.tglon2d, self.tglat2d, ice_target 
if __name__=="__main__":
    from plot_ts_vol_giomas import spatial_plot
    trgFile = 'soca_gridspec.nc'
    srcFile = 'heff.H2000.nc'
    grid = Grid(srcFile=srcFile, trgFile=trgFile)
    print(trgFile)
    #grid.source_grid()
    lon, lat, ice=grid.kdtree_interp()
    spatial_plot(lon, lat, ice, varname='total-ice-thickness_north', domain='north', title='total ice thickness', bound=[0, 5]) 
    '''
    fig = plt.figure(figsize=(28,12))
    cmap0=plt.cm.jet
    cmap0.set_under('darkblue') 
    cmap0.set_over('darkred')

    gs = GridSpec(1,3, width_ratios=[1,1, 0.05], wspace = 0.05)
    crs=ccrs.LambertConformal()
    # Left plot - ERA5 grid Nearest neighbor
    ax1 = plt.subplot(gs[0, 0], projection=crs)
    plot_background(ax1)
    ax1.contourf(lon, lat, ice,\
                   vmin=0, vmax=5, \
                   transform=ccrs.PlateCarree(),\
                   levels=np.arange(0, 5, 1.0),\
                   cmap=cmap0 )
    ax1.contour(lon, lat, ice, 
                          levels = np.arange(0, 5, 1.0), 
                          linewidths=2, 
                          colors='k',
                          transform = ccrs.PlateCarree())
    ax1.scatter(lon, lat, transform=ccrs.PlateCarree(), s=0.5)
    string_title=u'ice thickness: 2000-01-01'
    plt.title(string_title, size='xx-large')
    plt.savefig('ice_thickness_interp')
    '''
