from netCDF4 import Dataset, num2date, date2num
import numpy as np
import matplotlib.pyplot as plt
import scipy.stats as stats
import cartopy.crs as ccrs
import cartopy
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
import os
import yaml
from matplotlib import cm
import re
import glob

class Args():
  def __init__(self, pathtofiles=""):
    self.files          = glob.glob(pathtofiles)
    self.domain         = "global"
    self.bounds         = [ -0.1, 0.1 ]
    self.group          = "ombg"
    self.variable       = "obs_absolute_dynamic_topography"
    self.colormap       = "jet"
    self.title          = ""
    self.save           = "none"

def plotobs(args):
    var=[]
    lon=[]
    lat=[]
    qc=[]

    for fname in args.files:
        ncfile = Dataset(fname,'r')
        metadata_grp=ncfile.groups['MetaData']
        try:
          var_grp=ncfile.groups[args.group]
          var_tmp=float(args.scale)*np.squeeze(var_grp.variables[args.variable][:])
          if ( args.group == "ombg" ):
            var_tmp = -var_tmp
        except:
          if ( args.group == "ombg" ):
            var_grp_hofx=ncfile.groups["hofx"]
            var_grp_obs=ncfile.groups["ObsValue"]
            var_tmp=np.squeeze(var_grp_obs.variables[args.variable][:]-
                               (var_grp_hofx.variables[args.variable][:]-float(args.bias)))
          else:
            print("Wrong group")

        try:
            qc_grp=ncfile.groups['EffectiveQC0']
        except:
            try:
                qc_grp=ncfile.groups['EffectiveQC']
            except:
                qc_grp=ncfile.groups['PreQC']

        if ( np.shape(np.shape(var_tmp))[0] >=2 ):
          var_tmp=np.squeeze(var_tmp[:,int(args.channel)])
          qc_tmp=np.squeeze(qc_grp.variables[args.variable][:,int(args.channel)])
        else:
          var_tmp=np.squeeze(var_tmp[:])
          qc_tmp=np.squeeze(qc_grp.variables[args.variable][:])

        lon_tmp=np.squeeze(metadata_grp.variables['longitude'][:])
        lat_tmp=np.squeeze(metadata_grp.variables['latitude'][:])

        print(np.shape(qc_tmp))
        #if ( np.shape(np.shape(var_tmp))[0] >=2 ):
        #qc_tmp=np.squeeze(qc_tmp[:,int(args.channel)])

        ncfile.close()

        # Append the data
        lon=np.append(lon, lon_tmp)
        lat=np.append(lat, lat_tmp)
        var=np.append(var, var_tmp)
        qc=np.append(qc, qc_tmp)

    print(np.shape(qc))
    print(np.shape(var))
    I=np.where(qc==0)
    Iq=np.where(qc>0)
    proj_type=args.domain
    if  proj_type == 'global' or proj_type == 'hat10':
        proj = ccrs.Robinson(central_longitude=210)
    if proj_type == 'north':
        proj = ccrs.NorthPolarStereo()
    if proj_type == 'south':
        proj = ccrs.SouthPolarStereo()

    fig = plt.figure(figsize=(13,8))
    #fig = plt.figure(figsize=(10,6))
    ax = fig.add_subplot(1, 1, 1, projection=proj)
    if  proj_type == 'global':
        ax.set_global()
    if  proj_type == 'hat10':
        ax.set_extent([-100, 10, -5, 50], ccrs.PlateCarree())
    if proj_type == 'north':
        ax.set_extent([-180, 180, 50, 90], ccrs.PlateCarree())
    if proj_type == 'south':
        ax.set_extent([-180, 180, -90, -50], ccrs.PlateCarree())
    if proj_type=='local':
        ax.set_extent([-80, 30, 50, 87], crs=ccrs.PlateCarree())

    obsax=plt.scatter(
        lon[I],
        lat[I],
        c=var[I],
        s=.1,
        cmap=args.colormap,
        transform=ccrs.PlateCarree(),
        vmin=args.bounds[0], vmax=args.bounds[1])
    plt.scatter(lon[Iq],lat[Iq],
        color='black',
        s=2.0,
        transform=ccrs.PlateCarree())

    ax.add_feature(cartopy.feature.LAND, edgecolor='black')
    ax.add_feature(cartopy.feature.LAKES, edgecolor='black')
    ax.coastlines()
    plt.colorbar(obsax, shrink=0.5, pad=0.01).set_label(args.group)
    plt.title(args.title, fontsize=14, fontweight='bold')
    if ( args.save == 'none' ): plt.show()
    if ( args.save != 'none' ): plt.savefig(args.save,  bbox_inches='tight', pad_inches = 0.02)

if __name__ == '__main__':
    description = """ Ex: soca_plotobs.py -f /obs_out/2019/20190417*/ctrl/adt_*
                                          -g ombg
                                          -v absolute_dynamic_topography
                                          -b -.2 .2
                                          -c jet
                                          -q 0
                                          -d global
                  """
    # Command line argument
    parser = ArgumentParser(
        description=description,
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '-f',
        '--files',
        type=str, nargs='+',required=True)
    parser.add_argument(
        '-v',
        '--variable',
        help="ioda obs name (sea_surface_temperature, sea_surface_salinity, ...)",
        type=str, required=True)
    parser.add_argument(
        '-g',
        '--group',
        help="ioda groups [ObsError, ombg, oman, ObsValue, ...]",
        type=str, required=True)
    parser.add_argument(
        '-d',
        '--domain',
        help="global, hat10, north, south",
        type=str, default='global')
    parser.add_argument(
        '-s',
        '--save',
        help="filename.png",
        type=str, default='none')
    parser.add_argument(
        '-b',
        '--bounds',
        help="min, max",
        type=str, nargs='+',required=True)
    parser.add_argument(
        '-q',
        '--qc',
        help="qc flag to plot",
        type=str, required=True)
    parser.add_argument(
        '-c',
        '--colormap',
        help="jet, bwr, RdBu, ...",
        type=str, default='spring')
    parser.add_argument(
        '-t',
        '--title',
        help="title for the figure",
        type=str, default=' ')
    parser.add_argument(
        '-sc',
        '--scale',
        help="scaling factor",
        type=str, default=1.0)
    parser.add_argument(
        '-bi',
        '--bias',
        help="bias",
        type=str, default=0.0)
    parser.add_argument(
        '-ch',
        '--channel',
        type=str, default=1)

    args = parser.parse_args()

    plotobs(args)
