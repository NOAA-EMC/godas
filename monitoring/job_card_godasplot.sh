#!/bin/bash
# command line
# ------ bash submit_mtools.sh exp var start_date end_date

# Command: bash ioda_run.sh start_date  end_date
sbatch <<EOT
#!/bin/bash
#SBATCH --job-name=$1_$2                                                                                                                                 
#SBATCH --ntasks=2                                                                                                                                       
#SBATCH --qos=batch                                                                                                                                      
#SBATCH --partition=orion

#SBATCH --time=5:30:00                                                                                                                                  
#SBATCH --account=da-cpu                                                                                                                             
#SBATCH --output=$1_$2.log   # Standard output and error log                                                                                          
echo $PWD
#conda activate esmpy
bash godas_plotobs.sh -p /work/noaa/marine/jhossen/$1 -x $1 -v $2 -s $3 -e $4 -l 12
#bash godas_plotobs.sh -p /work/noaa/marine/jhossen/obs_filter_test/$1 -x $1 -v $2 -s $3 -e $4 -l 12
exit 0

EOT
