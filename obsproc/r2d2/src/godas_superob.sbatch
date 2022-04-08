#!/bin/bash
set -ex
while getopts "t:n:" option; do
   case $option in
      t) # job time hh:mm:ss
         job_time=$OPTARG;;
      n) # num pes
         npes=$OPTARG;;

   esac
done

jobname=superob-test

# Create superob yaml
cat << EOF > superob_config.yaml
grid:
  # I know, hardcoding a weird path, with an implicit dependency, shame on me.
  filename: /work/noaa/marine/Guillaume.Vernieres/runs/s2s/final-0.25/static/soca_gridspec.nc
  lat: lat
  lon: lon

binning:
  mode: superob
  errors:
    base: 0.0
    error mean mult: 1.0
    value stddev mult: 1.0

obs input file: sst_cat_test.nc
obs output file: superob_output.nc
EOF

cat << EOF > $jobname.sh
#!/bin/bash
#SBATCH --job-name=$jobname
#SBATCH --ntasks=144 
##SBATCH --nodes=1 
#SBATCH --qos=debug
##SBATCH --qos=batch
#SBATCH --time=$job_time
#SBATCH --account=marine-cpu
#SBATCH --output=${jobname}%j.log
#SBATCH --error=${jobname}%j.err
#SBATCH --exclusive
##SBATCH --partition=orion

echo $PWD

cd test
source /work/noaa/marine/Guillaume.Vernieres/runs/s2s/soca-science/configs/machine/machine.orion.intel
ln -s /work/noaa/marine/Guillaume.Vernieres/runs/s2s/build.intel/bin/obs_cat.x .
ln -s /work/noaa/marine/Guillaume.Vernieres/runs/s2s/broken-b/build/bin/obs_superob.x .
time srun -n $npes obs_cat.x -i sst -o sst_cat_test.nc
time ./obs_superob.x ../superob_config.yaml

EOF

sbatch $jobname.sh
