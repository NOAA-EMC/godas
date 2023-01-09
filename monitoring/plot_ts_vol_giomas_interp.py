import argparse
import numpy as np
import matplotlib
#matplotlib.use('agg')
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy
import netCDF4 as nc
import xarray as xr
import glob
import datetime
from dateutil.relativedelta import relativedelta
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from scipy.spatial import cKDTree

def spatial_plot(lon, lat, var, varname='ice_thickness', gridplot=True, \
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
    levels=[round(xx, 1) for xx in levels]
    obsax = ax.contourf(lon, lat, var,\
                   vmin=vmin, vmax=vmax, \
                   transform=ccrs.PlateCarree(),\
                   levels=levels,\
                   cmap='jet', extend='max' )
    ax.contour(lon, lat, var,
                          levels = levels,
                          colors='k',
                          transform = ccrs.PlateCarree())
    ax.add_feature(cartopy.feature.LAND, edgecolor='black')
    ax.add_feature(cartopy.feature.LAKES, edgecolor='black')
    ax.coastlines()
    ax.set_extent([lonmin, lonmax, latmin, latmax], ccrs.PlateCarree())
    plt.colorbar(obsax, shrink=0.5) #.set_label(varname)
    plt.title(title, fontsize=14, fontweight='bold')
    plt.savefig('figures/Fig_%s_%s.png'%(domain, varname),  bbox_inches='tight', pad_inches = 0.02)

def timeseries_plot(y0, t, seaice_nh, seaice_sh, title='time series', figname='ts_plot', ylabel=None):
    color=['b','r','k','m']
    plt.clf()
    plt.figure(figsize=(10, 5))
    date=datetime.datetime(int(y0),1,1,12,0)
    ndate=[ date + relativedelta(months=mm) for mm in range(t) ]
    # Total Volume
    #fig,ax = plt.subplots(figsize=(1024./100, 576./100))
    plt.plot(ndate, seaice_nh, '-', color=color[0],label='north')
    plt.plot(ndate, seaice_sh, '--', color=color[1],label='south')
    plt.legend(loc='best')
    plt.gcf().autofmt_xdate()
    plt.ylabel(ylabel)
    plt.xlabel('Date')
    plt.title(title, fontsize=14)
    plt.grid(True)
    plt.savefig('figures/'+figname+'_2019_new.png', bbox_inches='tight', pad_inches = 0.02, dpi=150)

class Common_grid:
    def __init__(self, gridFile=None):
        self.trgFile=gridFile

    def target_grid(self):
        target = xr.open_dataset(self.trgFile)
        self.tglat2d=target.lat[0]
        self.tglon2d=target.lon[0]

    def geo2cartesian(self, lon, lat):
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
        return x, y, z

    def kdtree_interp(self, lon, lat, zval):
        import time
        starttime=time.time()
        xs, ys, zs = self.geo2cartesian(lon.values.flatten(), lat.values.flatten())
        self.target_grid()
        xt, yt, zt = self.geo2cartesian(self.tglon2d.values.flatten(), self.tglat2d.values.flatten())
        tree = cKDTree(np.column_stack((xs, ys, zs)))
        d, inds = tree.query(np.column_stack((xt, yt, zt)), k = 1) #nterpolated 2d field
        ice_target = zval.values.flatten()[inds].reshape(self.tglon2d.shape)
        ice_target[ice_target > 9999.] = 0
        endtime=time.time()
        print("time for interpolation: ", endtime-starttime)
        #print('shape in kdtree', self.tglon2d.shape, self.tglat2d.shape, ice_target.shape)
        return self.tglon2d, self.tglat2d, ice_target

#################################################
class Icethk_validation(Common_grid):
    def __init__(self, var, gridFile):
        super().__init__(gridFile)
        self.var=var
        
    def readfiles(self, srcFile):
        source = xr.open_dataset(srcFile)
        geolat = source.variables['lat_scaler'][:]
        geolon = source.variables['lon_scaler'][:]
        self.ice = source.variables['heff'][:]
        #print("initial shape", self.ice.shape)
        dx = source.variables['dxt'][:]
        dy = source.variables['dyt'][:]
        self.area = (dx*dy)*1000*1000
        
        self.lat = geolat
        self.lon = geolon


    def max2d_ice(self):
        '''
        This calculate yearly maximum ice thickness over 2D grids. 
        The data is ice(n, j, i), where n -> months, j-> lat, i-> lon
        '''
        ice2d = np.max(self.ice, axis=0)
        lon, lat, ice2d = self.kdtree_interp(self.lon, self.lat, ice2d)
        return lon, lat, ice2d#, ice2d_nh, ice2d_sh

    def monthly_icemax(self):
        '''
        This calculates total sea-ice volume for each month 
        by summing up sea ice volume over the whole region
        '''
        ice1d=[]
        ice1d_nh=[]
        ice1d_sh=[]
        ice=self.ice
        ice=np.ma.masked_greater_equal(ice, 9999.)
        lat=self.lat
        for i in range(12):
            ice_nh  = np.ma.masked_where(lat < 0., ice[i])
            ice_sh  = np.ma.masked_where(lat > 0., ice[i])
            ice1d.append(ice[i].max())
            ice1d_nh.append(ice_nh.max())
            ice1d_sh.append(ice_sh.max())
        return ice1d, ice1d_nh, ice1d_sh

    def sum2d_icevol(self):
        '''
        This calculate yearly sea-ice volume over 2D grids by summing over months. 
        The data is ice(n, j, i), where n -> months, j-> lat, i-> lon    
        '''
        ice2d = 0
        for i in range(12):
            ice=self.ice[i]
            ice=np.ma.masked_greater_equal(ice, 9999)
            ice[ice.mask]=0
            ice=ice.data
            ice2d=ice2d+ ice
        icevol = ice2d * self.area/(10**9)
        lon, lat, icevol = self.kdtree_interp(self.lon, self.lat, icevol)
        #ice2d_nh  = np.ma.masked_where(self.lat < 0., ice2d)
        #ice2d_sh  = np.ma.masked_where(self.lat > 0., ice2d)
        return lon, lat, icevol # ice2d, ice2d_nh, ice2d_sh

    def monthly_icevol(self):
        '''
        This calculates total sea-ice volume for each month 
        by summing up sea ice volume over the whole region
        '''
        ice1d=[]
        ice1d_nh=[]
        ice1d_sh=[]
        ice=self.ice
        lat=self.lat
        for i in range(12):
            ice=self.ice[i]
            ice=np.ma.masked_greater_equal(ice, 9999)
            ice_vol=ice*self.area/(10**9)
            ice_nh  = np.ma.masked_where(lat < 0., ice_vol)
            ice_sh  = np.ma.masked_where(lat > 0., ice_vol)
            ice1d.append(ice_vol.sum())
            ice1d_nh.append(ice_nh.sum())
            ice1d_sh.append(ice_sh.sum())
        return ice1d, ice1d_nh, ice1d_sh

def main_ice_volume(gridFile, yearly_plot=False, title='total ice volume [$km^3$] (GIOMAS)'):
    t=0
    ################################################
    var = 'heff'
    icethk=Icethk_validation(var, gridFile) 
    for exp in ['/work/noaa/ng-godas/marineda/validation/GIOMAS']:
        lod=glob.glob(exp+'/'+'*'+'/')
        #lod=glob.glob(exp+'/'+'1990'+'/')
        lod.sort()
        y0=lod[0].split('/')[7]
        # for total volume over 2d grid
        tvol=0
        tvol_nh=0
        tvol_sh=0
        # for total volume as a timeseries
        ts_vol=[]
        ts_vol_nh=[]
        ts_vol_sh=[]

        for path2ioda in lod:
            yyyy=path2ioda.split('/')[7]
            lof=glob.glob(path2ioda+'heff.H'+'*.nc')
            # storing ice volume in each grids after summing over months
            ice2dsum=0
            ice2dnh_sum=0
            ice2dsh_sum=0
            for fname in lof:
                #print(fname)
                icethk.readfiles(fname)
                #print(ice.shape)
                # sum over 12 months
                lon, lat, ice2d = icethk.sum2d_icevol()
                if yearly_plot:
                    #spatial_plot(lon, lat, ice2d, varname='total-ice_volume-%s'%yyyy,\
                    #     title=title+" in "+yyyy, bound=[0, 70])
                    spatial_plot(lon, lat, ice2d, varname='total-ice_volume-%s'%yyyy,\
                         title=title+" in "+yyyy, domain='north', bound=[0, 70])
                    spatial_plot(lon, lat, ice2d, varname='total-ice_volume-%s'%yyyy,\
                         title=title+" in "+yyyy, domain='south', bound=[0, 70])
                ice2dsum = ice2dsum + ice2d
                # monthly ice volume, summing up over the whole region
                ice_1d, ice1d_nh, ice1d_sh = icethk.monthly_icevol()
                ts_vol.extend(ice_1d)
                ts_vol_nh.extend(ice1d_nh)
                ts_vol_sh.extend(ice1d_sh)

                t = t + 12  # this is for creating datetime in x-axis

            # total ice  volume cumulated over the years
            tvol=tvol+ice2dsum
        # ploting total ice volume accumulated during the period
        spatial_plot(lon, lat, tvol, varname='total-ice-vol', title=title)
        spatial_plot(lon, lat, tvol, varname='total-ice-vol', title=title, domain='north')
        spatial_plot(lon, lat, tvol, varname='total-ice-vol', title=title, domain='south')
        timeseries_plot(y0, t, ts_vol_nh, ts_vol_sh, figname='timeseries_tvol', \
                title=title, ylabel='ice volume [$km^3$]')        

def main_max_ice_thickness(gridFile, yearly_plot=False):
    t=0
    ################################################
    var = 'heff'
    #grid = Common_grid(trgFile)
    icethk = Icethk_validation(var, gridFile) 
    for exp in ['/work/noaa/ng-godas/marineda/validation/GIOMAS']:
        lod=glob.glob(exp+'/'+'*'+'/')
        #lod=glob.glob(exp+'/'+'1990'+'/')
        lod.sort()
        y0=lod[0].split('/')[7]
        # for sea ice thickness as a timeseries
        ithk_max = []
        ithk_max_nh = []
        ithk_max_sh = []
        # for sea ice thickness over 2d grid
        ithk2dmax = []
        ithk2dmax_nh = []
        ithk2dmax_sh = []

        for path2ioda in lod:
            yyyy=path2ioda.split('/')[7]
            lof=glob.glob(path2ioda+'heff.H'+'*.nc')
            # for storing max ice thickness in a year 
            ice2dmax=[]
            ice2dmax_nh=[]
            ice2dmax_sh=[]
            for fname in lof:
                #print(fname)
                icethk.readfiles(fname)
                #print(ice.shape)
                # max over 12 months on 2d grid
                #ice2d, ice2d_nh, ice2d_sh = icethk.max2d_ice()
                lon, lat, ice2d = icethk.max2d_ice()
                if yearly_plot:
                    spatial_plot(lon, lat, ice2d, varname='max-ice-thickness-%s'%yyyy,\
                         title='Max ice thickness [m] in '+yyyy, bound=[0, 5])
                    spatial_plot(lon, lat, ice2d, domain='north', varname='max_icethk-'+yyyy, \
                        title='Max ice thickness [m] (GIOMAS) '+yyyy, bound=[0,5])
                    spatial_plot(lon, lat, ice2d, domain='south', varname='max_icethk-'+yyyy, \
                        title='Max ice thickness [m] (GIOMAS) '+yyyy, bound=[0,5])
                #spatial_plot(lon, lat, ice2dnh_sum, varname='total_vol_%s'%yyyy, title='total_vol', domain='north')
                ice2dmax.append(ice2d)
                #ice2dmax_nh.append(ice2d_nh)
                #ice2dmax_sh.append(ice2d_sh)
                # monthly ice max, over the whole region
                ice_1d, ice1d_nh, ice1d_sh = icethk.monthly_icemax()
                ithk_max.extend(ice_1d)
                ithk_max_nh.extend(ice1d_nh)
                ithk_max_sh.extend(ice1d_sh)

                t = t + 12  # this is for creating datetime in x-axis

            # adding max as a list
            if ice2dmax != []:
                ice2dmax=np.max(ice2dmax, axis=0)
                ithk2dmax.append(ice2dmax)
                #ice2dmax_nh=np.max(ice2dmax_nh, axis=0)
                #ithk2dmax_nh.append(ice2dmax_nh)
                #ice2dmax_sh=np.max(ice2dmax_sh, axis=0)
                #ithk2dmax_sh.append(ice2dmax_sh)
   
        ithk2d_max=np.max(ithk2dmax, axis=0) 
        spatial_plot(lon, lat, ithk2d_max, varname='max_icethk', title='Max ice thickness [m] (GIOMAS)', bound=[0,5])
        spatial_plot(lon, lat, ithk2d_max, domain='north', varname='max_icethk', title='Max ice thickness [m] (GIOMAS)', bound=[0,5])
        spatial_plot(lon, lat, ithk2d_max, domain='south', varname='max_icethk', title='Max ice thickness [m] (GIOMAS)', bound=[0,5])
        timeseries_plot(y0, t, ithk_max_nh, ithk_max_sh, figname='timeseries_ithk_max', \
                title='maximum ice thickness [m]', ylabel='max ice thickness [m]' )        

if __name__=='__main__':
    description = """ Ex. plot_ts_vol_giomas.py -o volume 
                                          -b 0 5
       """
    # Command line argument
    parser = ArgumentParser(
        description=description,
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '-o',
        '--option',
        type=str, required=True)
    parser.add_argument(
        '-g',
        '--gridFile',
        type=str, required=True)
    parser.add_argument(
        '-b',
        '--bound',
        help="bound [min, max]",
        type=str, nargs='+',  default=[0, 5], required=False)
    args = parser.parse_args() 
    if args.option == "thickness":
        main_max_ice_thickness(args.gridFile)
    if args.option == "volume":
        main_ice_volume(args.gridFile)

