#!/usr/bin/env python3
import sys
from r2d2 import store
from solo.configuration import Configuration
from solo.date import date_sequence
import yaml
from yaml.loader import SafeLoader
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter, RawTextHelpFormatter
import os

def store_obs(yaml_file):
    config = Configuration(yaml_file)
    dates = date_sequence(config.start, config.end, config.step)
    obs_types = config.obs_types
    provider = config.provider
    experiment = config.experiment
    type = config.type
    source_dir = config.source_dir
    source_file = config.source_file
    step = config.step
    print(config)
    for date in dates:
        day = str(date).split('T')[0]
        year = day[0:4]
        month = day[4:6]
        day = day[6:8]
        for obs_type in obs_types:
            obs_prefix = obs_type.split('_')[0]
            store(
                provider=provider,
                type=type,
                experiment=experiment,
                database='shared',
                date=date,
                obs_type=obs_type,
                time_window=step,
                source_file=f'{source_dir}/{source_file}',
                ignore_missing=True,
            )



if __name__ == '__main__':
    description = 'example: ./soca_store_obs.py --start 20150101 --end 20150102 --source ./obs --provider rads --experiment benchmark --obstype adt --platforms 3a c2 j2 j3 sa \n' + \
    'list of observation types and platforms: \n' + \
    '  - adt: 3a, c2, j2, j3, sa, ... \n' + \
    '  - icec: EMC, ... \n' + \
    '  - icefb: GDR, ... \n' + \
    '  - insitu: hgodas, fnmoc, ... \n' + \
    '  - oc: EMC \n' + \
    '  - sst: noaa19, metopa, gmi, windsat, drifter, ... \n' + \
    '  - sss: smap, smos, aquarius, ... \n'

    # Command line arguments
    parser = ArgumentParser(description=description, formatter_class=RawTextHelpFormatter)
    parser.add_argument('--start', help='start date', type=str,required=True)
    parser.add_argument('--end', help='end date', type=str,required=True)
    parser.add_argument('--source', help='path to the original observations', type=str,required=True)
    parser.add_argument('--source_file', help='directory file name structure of the source file',
                        type=str, default='{year}/{year}{month}{day}/{obs_type}_{year}{month}{day}.nc')
    parser.add_argument('--provider', help='provider of the processed obervations (jcsda, rads, ...)',
                        type=str,required=True)
    parser.add_argument('--experiment', help='descriptor of the usage type (benchmark_obs, ...)',
                        type=str,required=True)
    parser.add_argument('--obstype', help='type of observations: sst, sss, adt, ...',
                        type=str,required=True)
    parser.add_argument('--platforms', help='platform of the observation type',
                        type=str, nargs='+',required=True)
    parser.add_argument('--step', help='duration of the file in iso somthing (P1D, PT10M, ...)',
                        type=str,default='P1D')
    parser.add_argument('--shared_db', help='path to the shared database',
                        type=str, default='/work/noaa/marine/marineda/r2d2/obs/')
    parser.add_argument('--local_db', help='path to the local database',
                        type=str, default='./r2d2-local/')
    parser.add_argument('--storage', help='local or shared',
                        type=str, default='local')

    args = parser.parse_args()

    # Assemble type/platforms
    tp=[]
    for p in args.platforms:
        tp.append(args.obstype+'_'+p)

    # Configure R2D2
    r2d2_config = {'databases': {'archive': {'bucket': 'archive.jcsda',
                                             'cache_fetch': True,
                                             'class': 'S3DB'},
                                 'local': {'cache_fetch': False,
                                           'class': 'LocalDB',
                                           'root': args.local_db},
                                 'shared': {'cache_fetch': False,
                                            'class': 'LocalDB',
                                            'root': args.shared_db}},
                   'fetch_order': ['shared'],
                   'store_order': [args.storage]}
    
    f = open('r2d2_config.yaml', 'w')
    yaml.dump(r2d2_config, f, sort_keys=False, default_flow_style=False)
    os.environ['R2D2_CONFIG'] = 'r2d2_config.yaml'

    # Create R2D2 database storage configuration
    obsstore = {'start': args.start,
                'end': args.end,
                'step': args.step,
                'source_dir': os.path.join(args.source, args.source_file),
                'type': 'ob',
                'provider': args.provider,
                'experiment': args.experiment,
                'obs_types': tp}
    f = open('store_obs.yaml', 'w')
    yaml.dump(obsstore, f, sort_keys=False, default_flow_style=False)

    # Store obs in R2D2
    store_obs('store_obs.yaml')
