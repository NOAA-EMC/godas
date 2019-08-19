#!/bin/bash
echo 'main_obs_prep.sh starts'
echo ${ROOT_GODAS_DIR}
echo CDATE is $CDATE

source ${ROOT_GODAS_DIR}/scripts/adt_prep_obs.sh 

#${ROOT_GODAS_DIR}/scripts/adt_prep_obs.sh

echo main_obs_prep ends
