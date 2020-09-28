#!/bin/bash

# Local Functions                                                    #
function ncdmnsz
{
      ncks --trd -m -M ${2}         \
    | grep -E -i ": ${1}, size ="   \
    | cut -f 7 -d ' '               \
    | uniq ;
}
set -eu

#load modules
source $UFS_INSTALL/$MACHINE.fcst

#reset input.nml
rm -rf input.nml
sh input.nml.tmp.sh > input.nml

#
tar -xvzf cice_mx.tgz
mkdir -p RESTART_IN
mkdir -p history
mkdir -p DATM_INPUT

#setup diag_table
sed -i "s+MDY+${MDY}+g" diag_table_tmp
sed -i "s+SYEAR+${SYEAR}+g" diag_table_tmp
sed -i "s+SMONTH+${SMONTH}+g" diag_table_tmp
sed -i "s+SDAY+${SDAY}+g" diag_table_tmp
sed -i "s+SHOUR+${SHOUR}+g" diag_table_tmp
mv diag_table_tmp diag_table

#setup DATM path
DATM_FILENAME_BASE=`echo $FORC_GEN_SOURCE | tr -s "[A-Z]" "[a-z]"`.  #The prefix of the forcing files for the DATM
DATMINPUTDIR="$FORC_SRC_DIR/$FORC_GEN_SOURCE/${SYEAR}${SMONTH}" #The path with the forcing
FORCING_SRC_LOW=`echo $FORC_GEN_SOURCE | tr -s "[A-Z]" "[a-z]"`

#setup path for next month
N=$((10#$SMONTH))
if [ $N == 12 ]; then
    NYEAR=$(($SYEAR+1))
    NMONTH=01
else
    NYEAR=$SYEAR
    NMONTH=$( printf '%02d' "$(($N+1))" )
fi
DATMINPUTDIR_NEXT="$FORC_SRC_DIR/$FORC_GEN_SOURCE/${NYEAR}${NMONTH}"

#nfhout number of hours between DATM inputs 6 for cfsr 3 for gefs
#IATM dimension of DATM input files, lon
#JATM dimension of DATM input files, lat
ForcingFile="$(ls "${DATMINPUTDIR}""/""${DATM_FILENAME_BASE}"*"nc" | tail -1)"
IATM=${IATM:-$(ncdmnsz "lon" "${ForcingFile}")}
JATM=${JATM:-$(ncdmnsz "lat" "${ForcingFile}")}

if [ "${FORC_GEN_SOURCE}" = "CFSR" ]; then
   NFHOUT=${NFHOUT:-6}
elif [ "${FORC_GEN_SOURCE}" = "GEFS" ]; then
   NFHOUT=${NFHOUT:-6}
else
   echo "Unknown forcing, exiting..."
   exit
fi

#set nems.configure
#Calculate bounds based on resource PETS
echo ${MODEL_RES}
if [[ "$MODEL_RES" == "1deg" ]]; then
    source ./module-setup.sh
    module use $( pwd -P )
    module load modules.datm
    module load ncl
    module load nco
    module list
    med_petlist_bounds=${med_petlist_bounds:-"$UFS_ATMPETS $(( $UFS_ATMPETS+$UFS_MEDPETS-1 ))"}
    atm_petlist_bounds=${atm_petlist_bounds:-"0 $(( $UFS_ATMPETS-1 ))"}
    ocn_petlist_bounds=${ocn_petlist_bounds:-"$(( $UFS_ATMPETS+$UFS_MEDPETS )) $(( $UFS_MEDPETS+$UFS_ATMPETS+$UFS_OCNPETS-1 ))"}
    ice_petlist_bounds=${ice_petlist_bounds:-"$(( $UFS_ATMPETS+$UFS_MEDPETS+$UFS_OCNPETS )) $(( $UFS_ATMPETS+$UFS_MEDPETS+$UFS_OCNPETS+$UFS_ICEPETS-1 ))"}
elif [[ "$MODEL_RES" == "0.25deg" ]]; then
    med_petlist_bounds=${med_petlist_bounds:-"0 $(( $UFS_MEDPETS-1 ))"}
    atm_petlist_bounds=${atm_petlist_bounds:-"0 $(( $UFS_ATMPETS-1 ))"}
    ocn_petlist_bounds=${ocn_petlist_bounds:-"$UFS_ATMPETS $(( $UFS_ATMPETS+$UFS_OCNPETS-1 ))"}
    ice_petlist_bounds=${ice_petlist_bounds:-"$(( $UFS_ATMPETS+$UFS_OCNPETS )) $(( $UFS_ATMPETS+$UFS_OCNPETS+$UFS_ICEPETS-1 ))"}
fi
sed -i -e "s;@\[med_petlist_bounds\];$med_petlist_bounds;g" nems.configure
sed -i -e "s;@\[atm_petlist_bounds\];$atm_petlist_bounds;g" nems.configure
sed -i -e "s;@\[ocn_petlist_bounds\];$ocn_petlist_bounds;g" nems.configure
sed -i -e "s;@\[ice_petlist_bounds\];$ice_petlist_bounds;g" nems.configure

#set model_configure
sed -i -e "s;@\[TASKS\];${NTASKS_TOT};g" model_configure
sed -i -e "s;@\[SYEAR\];${SYEAR};g" model_configure
sed -i -e "s;@\[SMONTH\];${SMONTH};g" model_configure
sed -i -e "s;@\[SDAY\];${SDAY};g" model_configure
sed -i -e "s;@\[SHOUR\];${SHOUR};g" model_configure
sed -i -e "s;@\[FHMAX\];${FCST_LEN};g" model_configure
sed -i -e "s;@\[IATM\];${IATM};g" model_configure
sed -i -e "s;@\[JATM\];${JATM};g" model_configure
sed -i -e "s;@\[CDATE\];${CDATE};g" model_configure
sed -i -e "s;@\[NFHOUT\];${NFHOUT};g" model_configure
sed -i -e "s;@\[FILENAME_BASE\];${DATM_FILENAME_BASE};g" model_configure

#set ice_in
if [[ -d /scratch1 ]] ; then
  NWPROD="/scratch1/NCEPDEV/global/glopara"
  NHOUR="$NWPROD/git/NCEPLIBS-prod_util/v1.1.0/exec/nhour"
 orion
elif [[ -d /work ]] ; then
  NHOUR="/apps/contrib/NCEPLIBS/lib/NCEPLIBS-prod_util/v1.1.0/exec/nhour"
fi
DT_CICE=900
stepsperhr=$((3600/${DT_CICE}))
nhours=$(${NHOUR} ${CDATE} ${SYEAR}010100)
istep0=$((nhours*stepsperhr))
npt=$((FCST_LEN*$stepsperhr))      # Need this in order for dump_last to work
nsec=$((FCST_LEN*3600))
sed -i -e "s;YEAR_INIT;${SYEAR};g" ice_in
sed -i -e "s;NPT;${npt};g" ice_in
sed -i -e "s;ISTEP0;${istep0};g" ice_in
sed -i -e "s;DT_CICE;${DT_CICE};g" ice_in
sed -i -e "s;NPROC_ICE;${UFS_ICEPETS};g" ice_in
sed -i -e "s;DUMPFREQ_N;${nsec};g" ice_in

# get ICs
mkdir -p INPUT
mkdir -p restart
(cd INPUT && ln -sf $MODEL_DATA_DIR/* .)
if [[ "$FCST_RESTART" == 1 ]]; then
    ln -sf $MODEL_RST_DIR_IN/MOM.res* RESTART_IN
    cp $MODEL_RST_DIR_IN/mediator* .
    cp $MODEL_RST_DIR_IN/ice.restart_file ./restart
    cp $MODEL_RST_DIR_IN/iced.$SYEAR-$SMONTH-$SDAY-*.nc ./restart
else
    exit 1
fi

# DATM forcing file name convention is ${DATM_FILENAME_BASE}.$YYYYMMDDHH.nc
echo "Link DATM forcing files"
ln -sf ${DATMINPUTDIR}/${DATM_FILENAME_BASE}*.nc ./DATM_INPUT/
ln -sf ${DATMINPUTDIR_NEXT}/${DATM_FILENAME_BASE}*.nc ./DATM_INPUT/

# Create scrip.nc
gridsrc=$(pwd)/DATM_INPUT/
gridfile=${FORCING_SRC_LOW}.${CDATE}.nc

sed -i "s+FORCING_SRC_LOW+${FORCING_SRC_LOW}+g" make_scripgrid.ncl
sed -i "s+GRIDSRC+${gridsrc}+g" make_scripgrid.ncl
sed -i "s+GRIDFILE+${gridfile}+g" make_scripgrid.ncl
sed -i "s+DIROUT+${gridsrc}+g" make_scripgrid.ncl

ncl < make_scripgrid.ncl
