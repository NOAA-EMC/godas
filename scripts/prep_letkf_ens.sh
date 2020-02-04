#! /bin/sh

######################################################################
######################################################################
#                                                                    #
# Overview of prep_letkf_ens.sh:                                     #
#  0.Create path for the LETKF                                       #
#  1.Copy fix files                                                  #
#  2.Copies/Links to the State and the HofX output                   #
#                                                                    #
######################################################################
######################################################################

while getopts "n:" opt; do
   case $opt in
      n) mbr=("$OPTARG");;
   esac
done
shift $((OPTIND -1))


## Main 
#--------------------------------------

RUNCDATE_GLBL=${RUNCDATE}
RUNCDATE=${RUNCDATE}

if [ -z "$mbr" ];then
   NEXTIC=${RUNCDATE}/../NEXT_IC
else
   NEXTIC=${RUNCDATE}/../NEXT_IC/mem${mbr}
   HOFXDIR=${RUNCDATE}/hofx/mem${mbr}
fi

echo "RUNCDATE     : ${RUNCDATE}" 
echo "LETKFDIR     : ${LETKFDIR}"
echo "NEXTIC       : ${NEXTIC}"
echo "HOFXDIR      : ${HOFXDIR}"
echo 

mkdir -p ${LETKFDIR}/Data/mem${mbr}
cd ${LETKFDIR}


# a. State: Softlink from NEXT_IC

ln -sf "${NEXTIC}/MOM.res.nc"                 \
       "${LETKFDIR}/Data/ocn.pert.ens.${mbr}.nc"

ln -sf "${NEXTIC}/MOM.res_1.nc"                 \
       "${LETKFDIR}/Data/ocn.pert.ens.${mbr}_1.nc"

icerst=$(cat ${NEXTIC}/restart/ice.restart_file)

ln -sf ${NEXTIC}/${icerst}                       \
       ${LETKFDIR}/Data/ice.pert.ens.${mbr}.nc

# b. HofX output (Observations)

cp -rf ${HOFXDIR}/Data/ioda.*.nc ${LETKFDIR}/Data/mem${mbr}/
find  ${LETKFDIR}/Data/mem${mbr}/ -type l -delete
