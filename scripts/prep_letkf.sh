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

cp $SOCA_STATIC/soca_gridspec.nc ${LETKFDIR}

cp $SOCA_STATIC/INPUT/layer_coord.nc            \
   ${LETKFDIR}/Vertical_coordinate.nc


# b. yaml file for UMD-LETKF
mkdir -p ${LETKFDIR}/yaml
cp -r $SOCA_CONFIG/letkf.yml ${LETKFDIR}/yaml/letkf.yaml
cp -r $SOCA_CONFIG/gridgen.yml ${LETKFDIR}/yaml/gridgen.yml


# Prep yaml for letkf
#----------------------------------------------------
${ROOT_GODAS_DIR}/scripts/replace_KWRD_yaml.sh     \
      -i $LETKFDIR/yaml/letkf.yaml                 \
      -k NO_ENS_MBR                                \
      -v ${mbr}
