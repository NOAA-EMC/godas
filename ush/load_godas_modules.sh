#!/bin/sh
#set -x

###############################################################
# Setup runtime environment by loading modules
ulimit_s=$( ulimit -S -s )
#ulimit -S -s 10000

# Find module command and purge:
source "$ROOT_GODAS_DIR/modulefiles/module-setup.sh.inc" 

# Load our modules:
module use "$ROOT_GODAS_DIR/modulefiles" 

if [[ -d /scratch1 ]] ; then
    # We are on NOAA Hera
        #module load hera.intel19
	module load hera.main
        module load hera.anaconda
        if [[ $1 = 'fcst' ]] ; then
                module purge
                # module load hera.intel19 
		module load hera.main
                module load hera.fcst
	fi
elif [[ -d /work ]] ; then
    # We are on MSU Orion
        source $ROOT_GODAS_DIR/modulefiles/orion.anaconda
        if [[ $1 != 'post' ]] ; then
                source $ROOT_GODAS_DIR/modulefiles/orion.intel19
        fi 
        if [[ $1 = 'fcst' ]] ; then
	              module purge
                source $ROOT_GODAS_DIR/modulefiles/orion.fcst
		            source $ROOT_GODAS_DIR/modulefiles/orion.anaconda 
        fi
else
    echo WARNING: UNKNOWN PLATFORM 
fi

module list

# Restore stack soft limit:
ulimit -S -s "$ulimit_s"
unset ulimit_s
