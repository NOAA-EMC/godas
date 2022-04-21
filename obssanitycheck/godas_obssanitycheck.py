from netCDF4 import Dataset, num2date, date2num
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from datetime import datetime, timedelta
from os.path import exists
import matplotlib.pyplot as plt
import numpy as np
import matplotlib.dates as mdates
import matplotlib.gridspec as gridspec
import sys
from glob import glob
import plotly.express as px
import pandas as pd
import plotly.io as pio

class ObsSanityCheck:
    def __init__(self,args=None):
        self.folder = args.path 
        self.start_date = args.start
        self.end_date = args.end
        self.year=self.start_date[0:4]
        self.args=args

    def extract_info_pt10m(self, folder=None):
        if folder is None:
            folder=self.folder
        file_descriptor=self.args.file_descriptor
        start_date=datetime.strptime(self.start_date, '%Y%m%d%H%M')
        end_date=datetime.strptime(self.end_date, '%Y%m%d%H%M')
        current_date=start_date
        missing_hours=[]
        nlocs=[]
        avail_dates=[]
        minval=[]
        maxval=[]
        while current_date < end_date:
            tmdhm=datetime.strftime(current_date, '%Y%m%d%H%M')
            ddir=folder+'/'+tmdhm[0:8]
            list_of_files=glob(ddir+'/*%s*%s*.nc*'%(file_descriptor, tmdhm))
            if not list_of_files:
                missing_hours.append(tmdhm[8:])
            else:
                nloc, minn, maxx=self.find_param(list_of_files[0])
                nlocs.append(nloc)
                minval.append(minn)
                maxval.append(maxx)
                if nloc==0: 
                    missing_hours.append(tmdhm[8:])
                avail_dates.append(current_date)
            current_date=current_date+timedelta(minutes=10)
        self.plot_info(nlocs, minval, maxval, avail_dates, missing_hours, freq='hours')


    def extract_info_p1d(self, folder=None):
        #file_descriptor=self.args.file_descriptor
        if folder== None:
            folder=self.folder
        start_date=datetime.strptime(self.start_date, '%Y%m%d').date()
        end_date=datetime.strptime(self.end_date, '%Y%m%d').date()
        missing_dates=[]
        nlocs=[]
        avail_dates=[]
        obsval=[]
        obserr=[]
        plf_data={}
        plf_missdates={}
        var_name=None
        for plf in self.args.platform:
            obstype=self.args.obstype
            current_date=start_date
            while current_date < end_date:
                ddir=folder+'/'+str(current_date)
                list_of_files=glob(ddir+'/*%s*%s*.nc*'%(obstype, plf))
                if not list_of_files:
                    plf_missdates.setdefault(plf, []).append(current_date)
                else:
                    nloc, minval, maxval=self.find_param(list_of_files[0], group='ObsValue')
                    nloc, minerr, maxerr=self.find_param(list_of_files[0], group='ObsError')
                    avail_dates.append(current_date)
                    plf_data.setdefault(plf, []).append([nloc, minval, maxval, minerr, maxerr, current_date])                    
                current_date=current_date+timedelta(days=1)
        self.plf_data=plf_data
        self.plf_missdates=plf_missdates
        if len(plf_data) !=0 : 
            self.plot_info(plf_data, plf_missdates, freq='dates')
        else:
            sys.exit('Nothing is found for the range of the date; check your database')
    #def plot_info(self, nlocs, obsval, obserr, var_name, avail_dates, missing_dates, freq=None):        
    def plot_info(self, plf_data, plf_missdates, freq=None):        
        
        #file_descriptor=self.args.file_descriptor
        formatter = mdates.DateFormatter('%Y/%m/%d')
        fig = plt.figure(figsize=(7,8), tight_layout=True)
        self.color_plf=['g','r','b','k','m','y']
        self.units={'sea_ice_area_fraction':'\%', 'absolute_dynamic_topography': 'm', \
            'ice_concentration':'\%', 'sea_surface_salinity':'psu', 'sea_water_salinity':'psu',
            'sea_surface_temperature':'C' }

        gs = gridspec.GridSpec(3, 3)
        ax = fig.add_subplot(gs[0, 0:2])
        self.plot_obscount(ax)
        # --- Plot min/max value of a variable
        ax = fig.add_subplot(gs[1, 0:2])
        self.plot_obsvalue(ax)
        # --- Plot min/max value of error 
        ax = fig.add_subplot(gs[2, 0:2])
        self.plot_obserror(ax)
        # --- Write missing files ----
        ax=fig.add_subplot(gs[:,2])
        self.write_missing_on_plot(ax)

        plt.suptitle("%s: %s-%s"%(self.args.obstype.upper(), self.start_date, self.end_date), y=.98, fontsize=14);
        plt.savefig('Fig_%s_%s_mm-%s-%s.png'%(self.year, self.args.obstype, self.start_date[4:6], self.end_date[4:6]), bbox_inches='tight', pad_inches=0.1)
   
    def plot_obscount(self, ax):
        nlocmax=[]
        nlocmin=[]
        i=0
        for plf in self.args.platform:
            if plf not in self.plf_data.keys():
                continue 
            data=self.plf_data[plf]
            data=np.array(data)
            nlocs=data[:,0]
            avail_dates=data[:,5]
            nlocs=[xx/1000 for xx in nlocs]
            nlocmax.append(max(nlocs))
            nlocmin.append(min(nlocs))
            ax.plot_date(avail_dates, nlocs,'-o', color=self.color_plf[i], label='%s'%plf)
            i=i+1

        ax.legend(ncol=min(2,len(self.args.platform)), labelspacing = 0.2, loc=0)
        ax.title.set_text('Obs Count ')
        ax.set_ylabel('No of obs data (in thousand)')
        ax.xaxis.set_major_locator(mdates.DayLocator(interval=10))
        ax.set_xticklabels([])
        if len(nlocs) != 0:
            ytkl= np.linspace(min(nlocmin), max(nlocmax), 5)
            yticks=['%sk'%int(xx) for xx in ytkl]
            ax.set_yticks(ytkl)
            ax.set_yticklabels(yticks)
 
    def plot_obserror(self, ax):
        #plt.title('error of %s'%var_name)
        if "_" in self.var_name:
            varr_name=self.var_name.replace('_', " ")
        plt.title('%s (%s)'%(varr_name, self.units[self.var_name]))
        i=0
        for plf in self.args.platform:
            if plf not in self.plf_data.keys():
                continue 
            data=self.plf_data[plf]
            data=np.array(data)
            minerr=data[:,3]
            maxerr=data[:,4]
            avail_dates=data[:,5]
            plt.plot_date(avail_dates, maxerr,'-s', markersize=6, color=self.color_plf[i], label='%s (max)'%plf)
            plt.plot_date(avail_dates, minerr,'-o', markersize=6,  color=self.color_plf[i],label='%s (min)'%plf)
            i=i+1
        ax.set_ylabel('Obs Error')
        ax.set_xlabel('dates')
        plt.grid(True)
        ax.legend(ncol=min(3,len(self.args.platform)), labelspacing = 0.2, loc=0)
        ax.xaxis.set_major_locator(mdates.DayLocator(interval=15))
        ax.set_xticklabels([])

    def plot_obsvalue(self, ax):
        #var_name=self.fxn(var_name)
        if "_" in self.var_name:
            varr_name=self.var_name.replace('_', " ")
        plt.title('%s (%s)'%(varr_name, self.units[self.var_name]))
        i=0
        for plf in self.args.platform:
            if plf not in self.plf_data.keys():
                continue 
            data=self.plf_data[plf]
            data=np.array(data)
            minval=data[:,1]
            maxval=data[:,2]
            avail_dates=data[:,5]
            plt.plot_date(avail_dates, maxval,'-s', markersize=6, color=self.color_plf[i], label='%s (max)'%plf)
            plt.plot_date(avail_dates, minval,'-o', markersize=6, color=self.color_plf[i],label='%s (min)'%plf)
            i=i+1
        ax.set_ylabel('Obs Value')
        plt.grid(True)
        #ax.legend(ncol=len(self.args.platform), loc=0)
        ax.legend(ncol=min(3,len(self.args.platform)), loc=0, fontsize=10, labelspacing=0.2)
        ax.xaxis.set_major_locator(mdates.DayLocator(interval=15))
        ax.set_xticklabels([])
    # --- extract no of observations and min/max value of a varibale -----
    def write_missing_on_plot(self, ax):
            
        #plt.title('Missing files (mm-dd)')
        xstep=0.01
        ystep=0.98
        # First write "not files exist"
        # then, write the "no missing files:
        # then write the date when files are missing
        for plf in self.args.platform:
            if plf not in self.plf_data.keys():
                plt.text(xstep, ystep, 'No files exist for %s!'%plf)
                ystep=ystep-0.03
                continue
            if plf not in self.plf_missdates.keys():
                plt.text(xstep, ystep, 'No missing files for %s!'%plf)
                ystep=ystep-0.03
                continue
        
        ystep=ystep-0.01
        # write dates when files are missing for some platforms.
        plt.text(xstep, ystep, 'Missing files (mm-dd)')
        ystep=ystep-0.035

        yheight=ystep
        for plf in self.args.platform:
            if plf not in self.plf_data.keys():
                continue
            if plf not in self.plf_missdates.keys():
                #ystep=ystep-0.05
                continue
            missing_dates=self.plf_missdates[plf]
            
            #ystep=ystep-0.05
            plt.text(xstep, ystep, 'PF: %s'%plf, bbox=dict(facecolor='none', edgecolor='red'), fontsize=10)
            for tx in missing_dates:
                #print(tx, tx.day)
                ystep=ystep-0.027
                if ystep < .01: 
                    xstep=xstep+0.355
                    ystep=yheight
                plt.text(xstep, ystep, '%02d-%02d |'%(tx.month, tx.day), fontsize=9)
            ystep=ystep-0.05
        ax.axis('off')

    def find_param(self, fname, group='ObsValue'):
        args=self.args
        ncfile = Dataset(fname,'r')
        metadata_grp=ncfile.groups['MetaData']
        var_grp=ncfile.groups[group]
        var_names=list(var_grp.variables)
        #print(var_names)
        var_name=var_names[0]
        var_tmp=np.squeeze(var_grp.variables[var_name][:])
        self.var_name=var_name
        nlocs=len(var_tmp)
        minval=0
        maxval=0
        if nlocs != 0:
            minval=min(var_tmp)
            maxval=max(var_tmp)
        ncfile.close()
        return nlocs,  minval, maxval
  
if __name__ == '__main__':
    description = """ Ex: godas_obssanitycheck.py -t adt -p c2 j2 j3 sa 3a -s start -e end -q P1D
                      Suggestions: limit the range between 3-6 months for daily data
                                for hourly or minutes data limit a day to few days       
                  """
    # Command line argument
    parser = ArgumentParser(
        description=description,
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument('-t', '--obstype', help='provide obstype (adt, sst, sss, icec,...)',
        type=str, required=True)
    parser.add_argument('-p', '--platform', help='provide platforms adt(c2, j2, ...), sst(noaa18, noaa19, ...), ...)',
        type=str, nargs='+', required=True)
    parser.add_argument('-s','--start',
        help="start date (yearmmdd, yearmmddhhmn, ...)",
        type=str, required=True)
    parser.add_argument( '-e','--end',
        help="end date in the format yearmmdd",type=str, required=True)
    parser.add_argument('--path',
        help="path of the data dir", type=str, required=False)
    parser.add_argument('-r', '--step', default='P1D',
        help="resolution for the data, such as P1D or PT10M", type=str, required=False)

    args = parser.parse_args()
    print(args)
    obj_sanity=ObsSanityCheck(args=args)

    if len(args.start)==8 and args.step=='P1D': 
        if args.path == None:        
            args.path='/work/noaa/ng-godas/r2d2/gdas_marine/ob/s2s_v1/P1D'
        obj_sanity.extract_info_p1d(folder=args.path)
    elif len(args.start)>8 and args.step == 'PT10M':
        if args.path == None:
            args.path='/work/noaa/ng-godas/r2d2/gdas_marine/ob/s2s_v1/PT10M' 
        obj_sanity.extract_info_pt10m(folder=args.path)
    else:
        sys.exit('inconsistent information. Please check your dates and step')

