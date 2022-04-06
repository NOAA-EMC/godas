from datetime import datetime
from netCDF4 import Dataset, num2date, date2num
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter
from datetime import datetime, timedelta
from os.path import exists
import matplotlib.pyplot as plt
import numpy as np
class Sanity:
    def __init__(self,args=None, filename=None, folder=None):
        self.fname = filename
        self.folder = folder
        self.start_date = args.start
        self.end_date = args.end
        self.year=self.start_date[0:4]
        self.var=None
        self.provider=None
        self.exp=None
        self.args=args

    def extract_info(self, provider, exp):
        file_descriptor=self.args.file_descriptor[0]
        start_date=datetime.strptime(self.start_date, '%Y%m%d').date()
        end_date=datetime.strptime(self.end_date, '%Y%m%d').date()
        print('date range:%s to %s'%(start_date, end_date))
        current_date=start_date#+timedelta(days=1)
        missing_dates=[]
        nlocs=[]
        avail_dates=[]
        minval=[]
        maxval=[]
        while current_date < end_date:
            r2d2_dir=self.folder+provider+'/ob/'+exp+'/P1D/'+str(current_date)
            #print(r2d2_dir)
            file_name='%s.%s.ob.P1D.%s.%sT00:00:00Z.nc4'%(provider,exp,file_descriptor,current_date)
            if exists(r2d2_dir+'/'+file_name):
                nloc=self.find_nlocs(r2d2_dir+'/'+file_name)
                nlocs.append(nloc)
                minn, maxx=self.find_minmax(r2d2_dir+'/'+file_name)
                minval.append(minn)
                maxval.append(maxx)
                avail_dates.append(current_date)
            else:
                missing_dates.append(current_date)
            current_date=current_date+timedelta(days=1)
        self.plot_info(nlocs, minval, maxval, avail_dates, missing_dates)

    def plot_info(self, nlocs, minval, maxval, avail_dates, missing_dates):        
        import matplotlib.dates as mdates
        import matplotlib.gridspec as gridspec
        file_descriptor=self.args.file_descriptor[0]
        formatter = mdates.DateFormatter('%Y/%m/%d')

        fig = plt.figure(tight_layout=True)
        gs = gridspec.GridSpec(2, 2)
        ax = fig.add_subplot(gs[0, 0])
        ax.plot_date(avail_dates, nlocs,'-og')
        ax.title.set_text('No of obs available on each day')
        ax.set_ylabel('No of obs')
        #ax.set_xlabel('Dates')
        ax.xaxis.set_major_locator(mdates.DayLocator(interval=10))
        #ax.xaxis.set_tick_params(rotation=45, labelsize=9)
        ax.set_xticklabels([])
        #fig, ax = plt.subplots()
        ax = fig.add_subplot(gs[1, 0])
        plt.title('Min and Max value on each day')
        plt.plot_date(avail_dates, minval,'-og', label='Min')
        plt.plot_date(avail_dates, maxval,'-*r', label='Max')
        ax.set_ylabel('Min/Max')
        #ax.set_xlabel('Dates')
        ax.legend(loc=0)
        ax.xaxis.set_major_locator(mdates.DayLocator(interval=10))
        #ax.xaxis.set_tick_params(rotation=40, labelsize=9)
        ax.set_xticklabels([])
        ax=fig.add_subplot(gs[:,1])
        plt.title('missing files on dates:')
        md_len=len(missing_dates)
        print('number of missing files', md_len)
        if md_len == 0:
            plt.text(.12, .75, 'No missing files!', fontsize=13)
            plt.text(.06, .65, 'from %s to %s'%(avail_dates[0], avail_dates[-1]))
        else:
            xstep=0.01
            ystep=0.95
            for tx in missing_dates:
                plt.text(xstep, ystep, '%s'%tx, fontsize=8)
                ystep=ystep-0.05
                if ystep < .005: 
                    xstep=xstep+0.33
                    ystep=0.95
        
        ax.set_xticklabels([])
        ax.set_yticklabels([])
        plt.suptitle("File descriptor: %s"%file_descriptor, y=.95);
        plt.savefig('Fig_%s_%s.png'%(file_descriptor, self.year), bbox_inches='tight', pad_inches=0.1)


    def find_nlocs(self, filename):
        args=self.args
        nc_fid = Dataset(filename,'r')
        nloc=nc_fid.variables['nlocs'].size
        nc_fid.close()
        return nloc

    def find_minmax(self, fname):
        args=self.args
        ncfile = Dataset(fname,'r')
        metadata_grp=ncfile.groups['MetaData']
        var_grp=ncfile.groups[args.group]
        var_tmp=np.squeeze(var_grp.variables[args.variable][:])
        minval=min(var_tmp)
        maxval=max(var_tmp)
        ncfile.close()
        return minval, maxval
        
if __name__ == '__main__':
    description = """ Ex: godas_obssanitycheck.py -f adt_c2 -o missing -g ObsValue 
                                       -v sea_surface_temperature -p /path/to/folder
                  """
    # Command line argument
    parser = ArgumentParser(
        description=description,
        formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '-f',
        '--file_descriptor',
        type=str, nargs='+',required=True)
    parser.add_argument(
        '-v',
        '--variable',
        help="ioda obs name (absolute_dynamic_topography, sea_surface_temperature, sea_surface_salinity, ...)",
        type=str, required=False)
    parser.add_argument(
        '-p',
        '--path',
        help="path name",
        type=str, required=False)
    parser.add_argument(
        '-s',
        '--start',
        help="start date in the format yearmmdd",
        type=str, required=True)
    parser.add_argument(
        '-e',
        '--end',
        help="end date in the format yearmmdd",
        type=str, required=True)
    parser.add_argument(
        '-g',
        '--group',
        help="ioda groups [ObsError, ombg, oman, ObsValue, ...]",
        type=str, required=True)
    
    args = parser.parse_args()
    provider='jcsda_soca'
    exp='benchmark_v2'
    if args.path == None:
        r2d2_root = '/work/noaa/marine/marineda/r2d2/obs/'
        print('base r2d2 dir:',r2d2_root)
    #print(args.file_descriptor)
    #print(args.variable)

    obs_sanity=Sanity(folder=r2d2_root, args=args)
    obs_sanity.extract_info(provider, exp)




