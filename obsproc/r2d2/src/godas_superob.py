#!/usr/bin/env python3
import sys
from r2d2 import fetch
from solo.configuration import Configuration
from solo.date import date_sequence
import yaml
import os
import glob

def fetch_obs():
    dates = date_sequence('2019-01-01T00:00:00Z', '2019-01-02T00:00:00Z', 'PT10M')
    obs_type = 'sst_noaa18_l3u'
    target_dir = 'test_fetch'
    step = 'PT10M'
    cnt = 0
    for date in dates:
        obs_prefix = obs_type.split('_')[0]
        print(obs_prefix)
        fout = './test/'+obs_prefix+'_'+str(cnt).zfill(4)+'.nc'
        cnt+=1
        print(cnt)
        fetch(
            provider='jcsda_soca',
            type='ob',
            experiment='benchmark_v2',
            database='local',
            date=date,
            obs_type=obs_type,
            time_window=step,
            ignore_missing=True,
            target_file=fout,
        )

def config_r2d2():
    # Configure R2D2
    r2d2_config = {'databases': {'archive': {'bucket': 'archive.jcsda',
                                             'cache_fetch': True,
                                             'class': 'S3DB'},
                                 'local': {'cache_fetch': False,
                                           'class': 'LocalDB',
                                           'root': '/work/noaa/marine/Guillaume.Vernieres/OBS/sprint1of4/convert2ioda/scratch/r2d2-local'},
                                 'shared': {'cache_fetch': False,
                                            'class': 'LocalDB',
                                            'root': ''}},
                   'fetch_order': ['local'],
                   'store_order': ['local']}

    f = open('r2d2_config.yaml', 'w')
    yaml.dump(r2d2_config, f, sort_keys=False, default_flow_style=False)
    os.environ['R2D2_CONFIG'] = 'r2d2_config.yaml'

if __name__ == '__main__':

    # Configure R2D2
    config_r2d2()

    # Fetch 10mn sst obs
    fetch_obs()

    # Count files, set the number of workers
    lof=glob.glob('./test/sst_????.nc')
    npes=len(lof)

    # Concatenate
    # os srun -n num_files obs_cat.x
    command='./godas_superob.sbatch -t 00:10:00 -n '+str(npes)
    os.system(command)

    print(command)
