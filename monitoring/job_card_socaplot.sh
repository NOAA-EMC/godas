#!/bin/bash
# command line
# ------ bash job_card_socaplot.sh exp var start_date end_date

sbatch <<EOT
#!/bin/bash
#SBATCH --job-name=$1_$2                                                                                                                                 
#SBATCH --ntasks=2                                                                                                                                       
#SBATCH --qos=batch                                                                                                                                      
#SBATCH --partition=orion

#SBATCH --time=7:30:00                                                                                                                                  
#SBATCH --account=da-cpu                                                                                                                             
#SBATCH --output=$1_$2.log   # Standard output and error log                                                                                          
echo $PWD

#bash soca_plotfield.sh -p /work/noaa/marine/jhossen/obs_filter_test/$1 -x $1 -v $2 -s $3 -e $4 -l 12
bash soca_plotfield.sh -p /work/noaa/marine/jhossen/$1 -x $1 -v $2 -s $3 -e $4 -l 12 

EOT
