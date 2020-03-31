#! /bin/sh 
set -e
######################################################################
######################################################################
#                                                                    #
#                                                                    # 
# Overview of prep_genenspert.sh                                     #
#                                                                    #
#                                                                    #
######################################################################
######################################################################

echo "Start of prep_genenspert.sh"

# Basic functions 
# ----------------------------------

# BF1. Make cice_bkg.nc fms compliant
cice2fms(){
   path=$1
   ncks -O -C -v aicen,vicen,vsnon $path/cice_bkg.nc $path/cice_bkg.nc
   ncrename -O -d ni,xaxis_1 -d nj,yaxis_1 -d ncat,zaxis_1 $path/cice_bkg.nc
   ncecat -O -v aicen,vicen,vsnon -u Time $path/cice_bkg.nc $path/cice_bkg.nc
   ncks -A -v Time,xaxis_1,yaxis_1,zaxis_1 $path/INPUT_MOM6/ice_model.res.nc $path/cice_bkg.nc
}

# BF2. 
cdate2window_begin(){ echo ${1:0:4}-${1:4:2}-${1:6:2}T00:00:00Z; }  # TODO: Hardcoded for 24hr DA window,

# BF3.
cdate2bkg_date(){ echo ${1:0:4}-${1:4:2}-${1:6:2}T12:00:00Z; }          # make generic.

####
## Main 
# Make sure CDATE is at 12z
cdate_hh(){ echo  ${1:8:2}; }
if [ $(cdate_hh $CDATE) -eq 12 ]; then
    echo "Setting SOCA config for 24hr DA window"
else
    echo "Background date needs to be at 12Z"
    echo "CDATE="$CDATE
    exit 1
fi
set -x
# Copy SOCA static files into RUNCDATE
#---------------------------------------------------
cp -r $SOCA_STATIC/* $RUNCDATE

# Adjust date in input.nml
cp $RUNCDATE/input-ymd.nml $RUNCDATE/input.nml
YYYY=$(echo  $CDATE | cut -c1-4)
MM=$(echo $CDATE | cut -c5-6)
DD=$(echo   $CDATE | cut -c7-8)
HH=$(echo  $CDATE | cut -c9-10)
sed -i "s/YYYY/${YYYY}/g" $RUNCDATE/input.nml
sed -i "s/MM/${MM}/g" $RUNCDATE/input.nml
sed -i "s/DD/${DD}/g" $RUNCDATE/input.nml
sed -i "s/HH/${HH}/g" $RUNCDATE/input.nml

# Copy SOCA config files into RUNCDATE
#----------------------------------------------------
mkdir -p $RUNCDATE/yaml
cp -r $SOCA_CONFIG/*.yml $RUNCDATE/yaml

# Prepare SOCA configuration
#-----------------------------------------
export window_begin=$(cdate2window_begin $CDATE)
export bkg_date=$(cdate2bkg_date $CDATE)

if [ $godas_cyc = "1" ]; then
    export window_length=PT24H
else
    echo "godas_cyc not valid"
    exit 1
fi
echo "window_begin="$window_begin
echo "window_length="$window_length
echo "bkg_date="$bkg_date


## Prep yaml for bump correlation initialization
#-----------------------------------------------
${ROOT_GODAS_DIR}/scripts/prep_BKG_DATE_yaml.sh    \
      -i $RUNCDATE/yaml/static_SocaError_init.yml  \
      -d ${bkg_date}

## Prep yaml for bump localization initialization
#------------------------------------------------
${ROOT_GODAS_DIR}/scripts/prep_BKG_DATE_yaml.sh    \
      -i $RUNCDATE/yaml/parameters_bump_loc.yml    \
      -d ${bkg_date}

## Prep yaml for checkpointing 
# TODO: Clean the following
   cdate2bkg_date(){ echo ${1:0:4}-${1:4:2}-${1:6:2}T12:00:00Z; }          # make generic.
export bkg_date=$(cdate2bkg_date $CDATE)

## Prep yaml for the soca_enspert
#-----------------------------------
${ROOT_GODAS_DIR}/scripts/prep_BKG_DATE_yaml.sh    \
      -i $RUNCDATE/yaml/genenspert.yml             \
      -d ${bkg_date}

${ROOT_GODAS_DIR}/scripts/replace_KWRD_yaml.sh     \
      -i $RUNCDATE/yaml/genenspert.yml             \
      -k NO_ENS_MBR                                \
      -v ${NO_ENS_MBR}

## Prep yaml for checkpointing 
#--------------------------------------------
${ROOT_GODAS_DIR}/scripts/prep_BKG_DATE_yaml.sh    \
      -i $RUNCDATE/yaml/checkpointmodel.yml        \
      -d ${bkg_date}

MEMBER_NO=1

while [[ $MEMBER_NO -le $NO_ENS_MBR ]]; do

   dum=$RUNCDATE/yaml/checkpointmodel$MEMBER_NO.yml

   cp -f $RUNCDATE/yaml/checkpointmodel.yml $dum
   
   ${ROOT_GODAS_DIR}/scripts/replace_KWRD_yaml.sh     \
         -i $dum                                      \
         -k OCN_FILENAME                              \
         -v ocn.pert.ens.$MEMBER_NO.nc
   ((MEMBER_NO = MEMBER_NO + 1))   
done 


echo "End of prep_genenspert.sh"
