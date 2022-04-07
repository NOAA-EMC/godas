#!/bin/bash
#SBATCH --job-name=iodaconv-test
#SBATCH --nodes=1 
#SBATCH --qos=debug
#SBATCH --time=00:10:00
#SBATCH --account=marine-cpu
#SBATCH --output=iodaconv%j.log
#SBATCH --error=iodaconv%j.err
#SBATCH --exclusive

echo $PWD

#time ./godas_obs2ioda.sh -s 20210101 -e 20210101 -i $PWD/data/ -o $PWD/ioda_data/ -t sst -d 'viirs_l3u' -n 40

./godas_obs2ioda.sh -s 20190101 -e 20190101 -i $PWD/ioda_data/ -t sst -d 'avhrr_l3u' -n 40
