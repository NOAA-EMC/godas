#! /bin/sh


#Variables which need to be defined: 


CDATE=${CDATE:-2011100100}
ROTDIR
DATA

#Defined Varaibles: 
SYEAR=$(echo  $CDATE | cut -c1-4)
SMONTH=$(echo $CDATE | cut -c5-6)
SDAY=$(echo   $CDATE | cut -c7-8)
SHOUR=$(echo  $CDATE | cut -c9-10)


#Variables that need to be defined list 
DIAG_TABLE=${DIAG_TABLE:-$PARM_FV3DIAG/diag_table}
MOM6_RESTART_SETTING


runtyp  'continue' 'initial'
ROTDIR
CDUMP
PDY
cyc

SCRIPTDIR

NTASKS_TOT
FHMAX=${FHMAX:-9}

DT_ATMOS
coupling_interval_fast_sec=${coupling_interval_fast_sec:-$DT_ATMOS}
FHOUT #nfhout
iatm: ${IATM}
jatm: ${JATM}
cdate0: ${CDATE}
nfhout: ${FHOUT} 
filename_base: ${FILENAME_BASE}
# 1.4 nems_configure 
ATMPETS=${ATMPETS:-"40"}   #Number of ATM Pets
MEDPETS=${MEDPETS:-$ATMPETS}  #Number of MED Pets
OCNPETS   #number of ocean pets
ICEPETS   #number of ice pets 
SCRIPTDIR  
confignamevarfornems  
cplflx=${cplflx:-".true."}
cplice=${cplice:-$cplflx}
DumpFields=${NEMSDumpFields:-false}

CPL_SLOW
CPL_FAST
restart_interval
inistep   #if [[ $inistep = "cold" ]] --- mediator coldstart not sure if this logic is totally right



######################################################################

# Overview: 
#0. Set up directories 
#1. Create input files 
#2. Copy fix files and IC files over 
#   Run forecast 
#   Copy output 


######################################################################

#0.  Set up directories 
        
if [ ! -d $ROTDIR ]; then mkdir -p $ROTDIR; fi        
if [ ! -d $DATA ]; then mkdir -p $DATA; fi
if [ ! -d $DATA/RESTART ]; then mkdir -p $DATA/RESTART; fi
if [ ! -d $DATA/INPUT ]; then mkdir -p $DATA/INPUT; fi
if [ ! -d $DATA/restart ]; then mkdir -p $DATA/restart; fi
if [ ! -d $DATA/history ]; then mkdir -p $DATA/history; fi
if [ ! -d $DATA/OUTPUT ]; then mkdir -p $DATA/OUTPUT; fi
if [ ! -d $DATA/MOM6_OUTPUT ]; then mkdir -p $DATA/MOM6_OUTPUT; fi
if [ ! -d $DATA/MOM6_RESTART ]; then mkdir -p $DATA/MOM6_RESTART; fi


# Go to Run Directory (DATA)         
cd $DATA 

######################################################################
######################################################################
#1. Inputs:                                                          #
# 1.1 input.nml                                                      # 
# 1.2 diag_table 
# 1.3 model_configure 
# 1.4 nems_configure 
# 1.5 MOM_input 
# 1.6 CICE input 
######################################################################
######################################################################


######################################################################
# 1.1 input.nml 
######################################################################

#Input.nml is an FMS file used by both FV3 and MOM6 

#MOM6 with DATM input.nml: 
cat > input.nml << EOF
&fms_nml
            clock_grain='ROUTINE'
            clock_flags='NONE'
            domains_stack_size = 5000000
            stack_size =0
/

&MOM_input_nml
         output_directory = 'MOM6_OUTPUT/',
         input_filename = '${MOM6_RESTART_SETTING:-"r"}'
         restart_input_dir = 'INPUT/',
         restart_output_dir = 'MOM6_RESTART/',
         parameter_filename = 'INPUT/MOM_input',
                              'INPUT/MOM_override' /
EOF

######################################################################
# 1.2 diag_table 
######################################################################

# diag_table is an FMS (FV3, MOM6) input file that determines outputs 

DIAG_TABLE=${DIAG_TABLE:-$PARM_FV3DIAG/diag_table}

# build the diag_table with the experiment name and date stamp
cat > diag_table << EOF
FV3 Forecast
$SYEAR $SMONTH $SDAY $SHOUR 0 0
EOF
cat $DIAG_TABLE >> diag_table


#diag_table
with open("diag_table_template",'rt') as inf:
 with open("diag_table",'wf') as outf:
   for x in inf.readlines():
    newline=x.replace('YMD',ymd) \
             .replace('SYEAR',str(year).zfill(4)) \
             .replace('SMONTH',str(month).zfill(2)) \
             .replace('SDAY',str(day).zfill(2))
    outf.write(newline)
EOT



######################################################################
# 1.3 model_configure 
######################################################################

#Model_configure is used by the NEMS driver, FV3 and DATM to get inputs

cat > model_configure <<EOF
total_member:              ${ENS_NUM:-1}
print_esmf:                ${print_esmf:-.true.}
PE_MEMBER01:               $NTASKS_TOT
start_year:                $SYEAR
start_month:               $SMONTH
start_day:                 $SDAY
start_hour:                $SHOUR
start_minute:              0
start_second:              0
nhours_fcst:               $FHMAX
RUN_CONTINUE:              ${RUN_CONTINUE:-".false."}
ENS_SPS:                   ${ENS_SPS:-".false."}

dt_atmos:                  ${DT_ATMOS}
atm_coupling_interval_sec: ${coupling_interval_fast_sec}

iatm:                      ${IATM}
jatm:                      ${JATM}
cdate0:                    ${CDATE}
nfhout:                    ${FHOUT} 
filename_base:             ${FILENAME_BASE}
EOF

######################################################################
# 1.4 nems_configure 
######################################################################


#nems.configure is used by NEMS driver so any model (including standalone FV3) 
# will need some version of this file 

rm -f $DATA/nems.configure

if [[ $inistep = "cold" ]]; then
  restart_interval=0
  coldstart=true     # this is the correct setting
else
  restart_interval=${restart_interval:-1296000}    # Interval in seconds to write restarts
  coldstart=false
fi

med_petlist_bounds=${med_petlist_bounds:-"0 $(( $MEDPETS-1 ))"}
atm_petlist_bounds=${atm_petlist_bounds:-"0 $(( $ATMPETS-1 ))"}
ocn_petlist_bounds=${ocn_petlist_bounds:-"$ATMPETS $(( $ATMPETS+$OCNPETS-1 ))"}  #120
ice_petlist_bounds=${ice_petlist_bounds:-"$(( $ATMPETS+$OCNPETS )) $(( $ATMPETS+$OCNPETS+$ICEPETS-1 ))"}  #48
wav_petlist_bounds=${wav_petlist_bounds:="$(( $ATMPETS+$OCNPETS+$ICEPETS )) $(( $ATMPETS+$OCNPETS+$ICEPETS+$WAVPETS-1 ))"}

medmod=${medmod:-"nems"}
atmmod=${atmmod:-"datm"}
ocnmod=${ocnmod:-"mom6"}
icemode=${icemod:-"cice"}

# Copy the selected template into run directory
cp $SCRIPTDIR/nems.configure.${confignamevarfornems}.IN tmp1
sed -i -e "s;@\[med_model\];$medmod;g" tmp1
sed -i -e "s;@\[atm_model\];$atmmod;g" tmp1
sed -i -e "s;@\[med_petlist_bounds\];$med_petlist_bounds;g" tmp1
sed -i -e "s;@\[atm_petlist_bounds\];$atm_petlist_bounds;g" tmp1

if [ $cplflx = .true. ]; then
        sed -i -e "s;@\[ocn_model\];$ocnmod;g" tmp1
        sed -i -e "s;@\[ocn_petlist_bounds\];$ocn_petlist_bounds;g" tmp1
        sed -i -e "s;@\[DumpFields\];$DumpFields;g" tmp1
        sed -i -e "s;@\[coldstart\];$coldstart;g" tmp1
        sed -i -e "s;@\[restart_interval\];$restart_interval;g" tmp1
        sed -i -e "s;@\[CPL_SLOW\];$CPL_SLOW;g" tmp1
        sed -i -e "s;@\[CPL_FAST\];$CPL_FAST;g" tmp1
fi
if [ $cplice = .true. ]; then
        sed -i -e "s;@\[ice_model\];$icemod;g" tmp1
        sed -i -e "s;@\[ice_petlist_bounds\];$ice_petlist_bounds;g" tmp1
fi

mv tmp1 nems.configure


######################################################################
# 1.5 MOM_input 
######################################################################



######################################################################
# 1.6 CICE input 
######################################################################

# parsing namelist of CICE (ice_in) 

#info on restarting CICE model is here: https://vlab.ncep.noaa.gov/redmine/projects/emc_fv3-mom6-cice5/wiki/Restarting_the_coupled_model#CICE5

#Variables needed: 
iceic=cice5_model.res_${CDATE}.nc  #name of file ice restart file gets renamed to
DT_CICE=900
stepsperhr=$((3600/${DT_CICE}))
nhours=$(${NHOUR} ${CDATE} ${SYEAR}010100)
istep0=$((nhours*stepsperhr))
npt=$((FHMAX*$stepsperhr))      # Need this in order for dump_last to work


FRAZIL_FWSALT=${FRAZIL_FWSALT:-".false."}
tr_pond_lvl=${tr_pond_lvl:-".true."}
restart_pond_lvl=${restart_pond_lvl:".false."}



histfreq_n=${histfreq_n:-6}
restart_interval=${restart_interval:-1296000}    # restart write interval in seconds, default 15 days
dumpfreq_n=$restart_interval                     # restart write interval in seconds

    #For CICE5 ice_in coldstart
    RUNTYPE='initial'
    # to dump a restart at the end of coldstart
    DUMPFREQ_N='3600'
    DUMPFREQ='s'
    USE_RESTART_TIME='.false.'

    #For CICE5 ice_in
    RUNTYPE='initial'
    # to dump a restart at the end of coldstart
    DUMPFREQ_N='5'
    DUMPFREQ='d'
    USE_RESTART_TIME='.false.'


# ice_calendar subroutine does not allow for writing restarts 
# at hour frequencies
# if DUMPFREQ is set as "h", then convert DUMPFREQ_N to seconds and
# reset DUMPFREQ to "s"
if("@[DUMPFREQ]" == "h"):
 dumpn = int("@[DUMPFREQ_N]")
 DUMPFREQ_N = str(dumpn*3600)
 DUMPFREQ = "s"
else:
 DUMPFREQ_N = str("@[DUMPFREQ_N]")
 DUMPFREQ = str("@[DUMPFREQ]")
#


# Copy the ice template into run directory
cp $SCRIPTDIR/ice_in_template tmp1
# Replace values in template
sed -i -e "s;YEAR_INIT;${SYEAR};g" tmp1
sed -i -e "s;ICE_IC_NAME;${iceic};g" tmp1
sed -i -e "s;NPT;${npt};g" tmp1
sed -i -e "s;ISTEP0;${istep0};g" tmp1
sed -i -e "s;DT_CICE;${DT_CICE};g" tmp1
sed -i -e "s;NPROC_ICE;${ICEPETS};g" tmp1
sed -i -e "s;RUNTYPE;${RUNTYPE};g" tmp1
sed -i -e "s;USE_RESTART_TIME;${USE_RESTART_TIME};g" tmp1
sed -i -e "s;DUMPFREQ_N;${DUMPFREQ_N};g" tmp1
sed -i -e "s;DUMPFREQ;${DUMPFREQ};g" tmp1
sed -i -e "s;FRAZIL_FWSALT;${FRAZIL_FWSALT};g" tmp1
sed -i -e "s;TR_POND_LVL;${tr_pond_lvl};g" tmp1
sed -i -e "s;RESTART_POND_LVL;${restart_pond_lvl};g" tmp1

# Rename to proper input ice input name
mv tmp1 ice_in 



######################################################################
######################################################################
# 2. Copy inputs 

#2.1 Copy DATM  inputs and fix files
#2.2 Copy MOM6 inputs and fix files
#2.3  Copy Mediator inputs 
#2.4 Copy CICE5 inputs and fix files 

######################################################################
######################################################################


######################################################################
#2.1 Copy DATM  inputs and fix files
######################################################################


######################################################################
#2.2 Copy MOM6 inputs and fix files
######################################################################

        
# Copy MOM6 ICs (from CFSv2 file)        
cp -pf $ICSDIR/$CDATE/mom6_da/MOM*nc $DATA/INPUT/
        
# Copy MOM6 fixed files        
cp -pf $FIXmom/INPUT/* $DATA/INPUT/

# Copy grid_spec and mosaic files
cp -pf $FIXgrid/$CASE/${CASE}_mosaic* $DATA/INPUT/
cp -pf $FIXgrid/$CASE/grid_spec.nc $DATA/INPUT/
cp -pf $FIXgrid/$CASE/ocean_mask.nc $DATA/INPUT/
cp -pf $FIXgrid/$CASE/land_mask* $DATA/INPUT/


######################################################################
#2.3  Copy Mediator inputs 
######################################################################

# Copy mediator restart files to RUNDIR       
if [ $runtyp = 'continue' ]; then             
  cp $ROTDIR/$CDUMP.$PDY/$cyc/mediator_* $DATA/
fi


######################################################################
#2.4 Copy CICE5 inputs and fix files 
######################################################################


        
# Copy CICE5 IC - pre-generated from CFSv2
cp -p $ICSDIR/$CDATE/cice5_model_0.25.res_$CDATE.nc $DATA/$iceic
#cp -p $ICSDIR/$CDATE/cpc/cice5_model_0.25.res_$CDATE.nc ./cice5_model.res_$CDATE.nc

# Copy CICE5 fixed files, and namelists
cp -p $FIXcice/kmtu_cice_NEMS_mx025.nc $DATA/
cp -p $FIXcice/grid_cice_NEMS_mx025.nc $DATA/

# Copy grid_spec and mosaic files
cp -pf $FIXgrid/$CASE/${CASE}_mosaic* $DATA/INPUT/
cp -pf $FIXgrid/$CASE/grid_spec.nc $DATA/INPUT/
cp -pf $FIXgrid/$CASE/ocean_mask.nc $DATA/INPUT/
cp -pf $FIXgrid/$CASE/land_mask* $DATA/INPUT/




######################################################################
######################################################################
# Run forecast 
######################################################################
######################################################################


######################################################################
######################################################################
# Copy outputs: 
######################################################################
######################################################################

#If a cold mediator start, copy the mediator files: 
if [ $runtyp = 'initial' ]; then
  cp $DATA/mediator_* $ROTDIR/$CDUMP.$PDY/$cyc/
fi


