#!/bin/ksh

######################################################################
######################################################################
#                                                                    #
# Overview of prep_letkf.sh:                                         #
#                                                                    #
#                                                                    #
######################################################################
######################################################################

while getopts "n:" opt; do
   case $opt in
      n) mbr=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

[ -z "$mbr" ] || [ -z "${LETKFDIR}" ] && exit

# Basic functions 
# ----------------------------------
cdate2bkg_date(){ echo ${1:0:4}-${1:4:2}-${1:6:2}T12:00:00Z; }          # make generic.            

## Main 
#--------------------------------------
cdate_hh(){ echo  ${1:8:2}; }
if [ $(cdate_hh $CDATE) -eq 12 ]; then
    echo "Setting SOCA config for 24hr DA window"
else
    echo "Background date needs to be at 12Z"
    echo "CDATE="$CDATE
    exit 1
fi

echo "RUNCDATE     : ${RUNCDATE}" 
echo "LETKFDIR     : ${LETKFDIR}"
echo

mkdir -p ${LETKFDIR}
cd ${LETKFDIR}

# Copy/Link files into local RUNCDATE (aka LETKFDIR)
#---------------------------------------------------
# a. grid information

cp $SOCA_STATIC/INPUT/layer_coord.nc            \
   ${LETKFDIR}/Vertical_coordinate.nc

# b. yaml file for UMD-LETKF
mkdir -p ${LETKFDIR}/yaml
cp -r $SOCA_CONFIG/letkf.yml ${LETKFDIR}/yaml/letkf.yaml
cp -r $SOCA_CONFIG/gridgen.yml ${LETKFDIR}/yaml/gridgen.yml
cp -r $SOCA_CONFIG/ensrecenter.yml ${LETKFDIR}/yaml/ensrecenter.yml
cp -r $SOCA_CONFIG/ensrecenter.yml ${LETKFDIR}/yaml/ensrecenter.yml
cp -r $SOCA_CONFIG/checkpointmodel.yml ${LETKFDIR}/yaml/checkpointmodel.yml

# Copy SOCA static files into RUNCDATE                                                                      
#---------------------------------------------------                                                        
cp -r $SOCA_STATIC/* ${LETKFDIR}

# Adjust date in input-mom6.nml                                                                                  
echo "CDATE is $CDATE" 
cp ${LETKFDIR}/input-ymd.nml $LETKFDIR/input-mom6.nml
YYYY=$(echo  $CDATE | cut -c1-4)
MM=$(echo $CDATE | cut -c5-6)
DD=$(echo   $CDATE | cut -c7-8)
HH=$(echo  $CDATE | cut -c9-10)
sed -i "s/YYYY/${YYYY}/g" $LETKFDIR/input-mom6.nml
sed -i "s/MM/${MM}/g" $LETKFDIR/input-mom6.nml
sed -i "s/DD/${DD}/g" $LETKFDIR/input-mom6.nml
sed -i "s/HH/${HH}/g" $LETKFDIR/input-mom6.nml

# Prep yaml for letkf
#----------------------------------------------------
${ROOT_GODAS_DIR}/scripts/replace_KWRD_yaml.sh     \
      -i $LETKFDIR/yaml/letkf.yaml                 \
      -k NO_ENS_MBR                                \
      -v ${mbr}

# Prep yaml for letkf                                                                                         
#----------------------------------------------------                                                         
export bkg_date=$(cdate2bkg_date $CDATE)
echo "bkg_date="$bkg_date

${ROOT_GODAS_DIR}/scripts/prep_BKG_DATE_yaml.sh    \
      -i $LETKFDIR/yaml/ensrecenter.yml    \
      -d ${bkg_date}

${ROOT_GODAS_DIR}/scripts/prep_recenter_yaml.sh     \
      -i $LETKFDIR/yaml/ensrecenter.yml                 \
      -d $LETKFDIR                                \
      -n ${mbr}

${ROOT_GODAS_DIR}/scripts/prep_BKG_DATE_yaml.sh    \
      -i $LETKFDIR/yaml/checkpointmodel.yml        \
      -d ${bkg_date}

MEMBER_NO=1

while [[ $MEMBER_NO -le $NO_ENS_MBR ]]; do

   dum=$LETKFDIR/yaml/checkpointmodel$MEMBER_NO.yml

   cp -f $LETKFDIR/yaml/checkpointmodel.yml $dum

   ${ROOT_GODAS_DIR}/scripts/replace_KWRD_yaml.sh     \
         -i $dum                                      \
         -k OCN_FILENAME                              \
         -v ocn.ana.$MEMBER_NO.nc

   ${ROOT_GODAS_DIR}/scripts/replace_KWRD_yaml.sh     \
         -i $dum                                      \
         -k ICE_FILENAME                              \
         -v ice.pert.ens.$MEMBER_NO.nc

   ((MEMBER_NO = MEMBER_NO + 1))
done


