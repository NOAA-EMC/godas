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
                source_file=f'{source_dir}/{year}/{year}{month}{day}/{obs_type}_{year}{month}{day}.nc',
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

    # command line arguments
    parser = ArgumentParser(description=description, formatter_class=RawTextHelpFormatter)
    parser.add_argument('--start', help='start date', type=str,required=True)
    parser.add_argument('--end', help='end date', type=str,required=True)
    parser.add_argument('--source', help='path to the original observations', type=str,required=True)
    parser.add_argument('--provider', help='provider of the processed obervations (jcsda, rads, ...)',
                        type=str,required=True)
    parser.add_argument('--experiment', help='descriptor of the usage type (benchmark_obs, ...)',
                        type=str,required=True)
    parser.add_argument('--obstype', help='type of observations: sst, sss, adt, ...',
                        type=str,required=True)
    parser.add_argument('--platforms', help='platform of the observation type',
                        type=str, nargs='+',required=True)
    args = parser.parse_args()

    # assemble type/platforms
    tp=[]
    for p in args.platforms:
        tp.append(args.obstype+'_'+p)

    # Create the R2D2 database
    obsstore = {'start': args.start,
                'end': args.end,
                'step': 'P1D',
                'source_dir': args.source,
                'type': 'ob',
                'provider': args.provider,
                'experiment': args.experiment,
                'obs_types': tp}
    f = open('store_obs.yaml', 'w')
    yaml.dump(obsstore, f, sort_keys=False, default_flow_style=False)
    store_obs('store_obs.yaml')
