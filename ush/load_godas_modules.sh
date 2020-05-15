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
	module load hera.anaconda
        module load hera.intel18
elif [[ -d /work ]] ; then
    # We are on MSU Orion
	module load orion.anaconda
        module load orion.intel19
else
    echo WARNING: UNKNOWN PLATFORM 
fi

# Restore stack soft limit:
ulimit -S -s "$ulimit_s"
unset ulimit_s
