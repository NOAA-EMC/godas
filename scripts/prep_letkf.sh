#! /bin/sh

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

## Main 
#--------------------------------------
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
