#! /bin/sh

######################################################################
######################################################################
#                                                                    #
# Overview of prep_hofx.sh:                                          #
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

# Basic functions 
# ----------------------------------

# BF1. Make cice_bkg.nc fms compliant
cice2fms(){
   path=$1
   ncks -O -C -v aicen,vicen,vsnon $path/cice_bkg.nc $path/cice_bkg.nc
   ncrename -O -d ni,xaxis_1 -d nj,yaxis_1 -d ncat,zaxis_1 $path/cice_bkg.nc
   ncecat -O -v aicen,vicen,vsnon -u Time $path/cice_bkg.nc $path/cice_bkg.nc
   echo $path
   ncks -A -v Time,xaxis_1,yaxis_1,zaxis_1 $path/INPUT_MOM6/ice_model.res.nc $path/cice_bkg.nc
}

# BF2. 
cdate2window_begin(){ echo ${1:0:4}-${1:4:2}-${1:6:2}T00:00:00Z; }  # TODO: Hardcoded for 24hr DA window,

# BF3.
cdate2bkg_date(){ echo ${1:0:4}-${1:4:2}-${1:6:2}T12:00:00Z; }          # make generic.

## Main 
#--------------------------------------

if [ -z "$mbr" ]
then

   RUNCDATE_GLBL=${RUNCDATE}   
   RUNCDATE=${RUNCDATE}

else

   RUNCDATE_GLBL=${RUNCDATE}
   RUNCDATE=${RUNCDATE}"/hofx/mem"$mbr

fi

echo "RUNCDATE is ${RUNCDATE}" 

mkdir -p ${RUNCDATE}


# Copy SOCA static files into RUNCDATE
#---------------------------------------------------
cp -r $SOCA_STATIC/* ${RUNCDATE}

# Adjust date in input.nml
cp ${RUNCDATE}/input-ymd.nml $RUNCDATE/input.nml
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
mkdir -p ${RUNCDATE}/yaml
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

      
# Create run hofx directory for each mem
#----------------------------------
   HOFXDIR=$RUNCDATE
   NEXTIC=$RUNCDATE_GLBL/../NEXT_IC/mem${mbr}
  
   mkdir -p ${HOFXDIR}


# Link to the processed obervations for the current CDATE
echo `ln -sf ${RUNCDATE_GLBL}/Data/ ${HOFXDIR}/Data`


# Copy the background from the fcst/mem*
#----------------------------------
   cp ${NEXTIC}/MOM*.nc $HOFXDIR
   icerst=$(cat ${NEXTIC}/restart/ice.restart_file)
   cp ${NEXTIC}/$icerst $HOFXDIR/cice_bkg.nc
      
   cice2fms $HOFXDIR

# Prep yaml for HofX for each member
#----------------------------------
   yamlfile=$RUNCDATE/yaml/hofx3d${mbr}.yml

   cp -r $RUNCDATE/yaml/hofx3d.yml ${yamlfile}


# Set date for hofx
   sed -i "s/WINDOW_BEGIN/${window_begin}/g" ${yamlfile}
   sed -i "s/WINDOW_LENGTH/${window_length}/g" ${yamlfile}
   sed -i "s/BKG_DATE/${bkg_date}/g" ${yamlfile}
   sed -i "s/OCN_FILENAME/MOM.res.nc/g" ${yamlfile}
   sed -i "s/ICE_FILENAME/cice_bkg.nc/g" ${yamlfile}

   ${ROOT_GODAS_DIR}/scripts/replace_KWRD_yaml.sh     \
      -i ${yamlfile}                                  \
      -k BASE_NAME                                    \
      -v ./INPUT
#      -v ${HOFXDIR} # When the path is long, the run fails

   ${ROOT_GODAS_DIR}/scripts/SetupJoCostFunction.sh   \
      -i ${yamlfile}                                  \
      -d $RUNCDATE

   ${ROOT_GODAS_DIR}/scripts/replace_KWRD_yaml.sh     \
      -i ${yamlfile}                                  \
      -k OBSDATAOUT                                   \
      -v ${HOFXDIR}/Data 
