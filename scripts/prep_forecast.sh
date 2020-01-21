#! /bin/sh

######################################################################
######################################################################
#                                                                    #
# Overview of prep_forecast.sh:                                      #
#                                                                    #
# 1. Set up directories                                              #
# 2. Create input files                                              #
# 3. Copy fix files                                                  #
# 4. Copy restart/IC files                                           #
#                                                                    #
######################################################################
######################################################################

while getopts "n:" opt; do
   case $opt in
      n) mbr=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

if [ -z "$mbr" ]
then 
   DATA=${RUNCDATE}/fcst
   nextic=$RUNCDATE/../NEXT_IC
   keepic=$RUNCDATE/../${CDATE}_IC
else
   DATA=${RUNCDATE}"/fcst/mem"$mbr
   nextic=$RUNCDATE/../NEXT_IC/mem$mbr
   keepic=$RUNCDATE/../${CDATE}_IC/   
fi
#Variables which need to be defined: 

#Generic variables 
#CDATE=${CDATE:-2011100100}   #YYYYMMDDHH --  start time
SCRIPTDIR=${ROOT_GODAS_DIR}/scripts
TEMPLATEDIR=${ROOT_GODAS_DIR}/scripts/templates
FIXmom=${ROOT_GODAS_DIR}/fix/MOM6_FIX_mx025
FIXcice=${ROOT_GODAS_DIR}/fix/CICE_FIX_mx025
FHMAX=${FHMAX:-24} #total forecast length in hours
restart_interval=${restart_interval:-86400}  # number of seconds for writing restarts (for non-cold start) default to 1 day interval

echo "CDATE is $CDATE"
echo "RUNCDATE is ${RUNCDATE}" 
echo "DATA is ${DATA}"
echo "SCRIPTDIR is $SCRIPTDIR"
echo "TEMPLATEDIR is $TEMPLATEDIR"
echo "FHMAX is $FHMAX"
echo "restart interval is ${restart_interval}"

#################################
# Variables that are for the most part hard coded but could be pulled out and configured/etc. 

#Both of these variables could be used for if/else later, but basically have hard coded for simplicity 
runtyp=${runtp:-'continue'}  # run type=  'continue' 'initial'
inistep=${inistep:-"warm"}  # inistep=cold for mediator cold start 

cplflx=${cplflx:-".true."}  #couple with ocean/ice model 
cplice=${cplice:-$cplflx}   #couple with ice model

#DATM Variables: 
#resources/basics:
atmmod=${atmmod:-"datm"} 
ATMPETS=${ATMPETS:-"72"}   #Number of ATM Pets
# model_configure variables 
DT_ATMOS=${DT_ATMOS:-900}  #DATM time step [seconds]
coupling_interval_fast_sec=${coupling_interval_fast_sec:-$DT_ATMOS} #likely can be depricated from DATM
DATM_FILENAME_BASE=${DATM_FILENAME_BASE:-'cfsr.'} #The prefix of the forcing files for the DATM
#for cfsr:  (will be different for gefs)
NFHOUT=${NFHOUT:-6}  #nfhout number of hours between DATM inputs 6 for cfsr 3 for gefs    
IATM=${IATM:-1760}  #dimension of DATM input files, lon     
JATM=${JATM:-880}   #dimension of DATM input files, lat

# MOM6 Ocean Variables 

#resource/basic
ocnmod=${ocnmod:-"mom6"}
OCNPETS=${OCNPETS:-"120"}  #number of ocean pets
#MOM_input 
DT_THERM_MOM6=${DT_THERM_MOM6:-"1800"}  #MOM6 thermodynamic time step  [seconds]
DT_DYNAM_MOM6=${DT_DYNAM_MOM6:-"900"}   #MOM6 dynamic time step   [seconds]
#diag table (FMS) 
DIAG_TABLE=${DIAG_TABLE:-$TEMPLATEDIR/diag_table_template}
#input.nml (FMS) 
MOM6_RESTART_SETTING=${MOM6_RESTART_SETTING:-"r"}  #MOM6 restart setting 'r' or 'n'

# CICE5 Ice Variables 

#resource/basic
icemod=${icemod:-"cice"}
ICEPETS=${ICEPETS:-"48"}   #number of ice pets 

#ice_input 
ceic=cice5_model.res_${CDATE}.nc  #name of file ice restart file gets renamed to
DT_CICE=${DT_CICE:-$DT_ATMOS}     #CICE time step [seconds]  

#Mediator/NEMS variables

#resource/basic 
medmod=${medmod:-"nems"}
MEDPETS=${MEDPETS:-$ATMPETS}  #Number of MED Pets

#nems.configure 
DumpFields=${NEMSDumpFields:-false}   #Dump diagnostic netcdf fields from component model caps
CPL_SLOW=${CPL_SLOW:-$DT_THERM_MOM6}  #slow coupling time step
CPL_FAST=${CPL_FAST:-$DT_ATMOS}       #fast coupling time step 

#Calculated Variables: 
SYEAR=$(echo  $CDATE | cut -c1-4)
SMONTH=$(echo $CDATE | cut -c5-6)
SDAY=$(echo   $CDATE | cut -c7-8)
SHOUR=$(echo  $CDATE | cut -c9-10)
NTASKS_TOT=${NTASKS_TOT:-"$(( $ATMPETS+$OCNPETS+$ICEPETS ))"} #240
NEARESTCDATE=$(echo $CDATE | cut -c1-8)00

######################################################################
######################################################################
# 1.  Set up directories                                             #
######################################################################
######################################################################

echo "Set up Directories"        
#if [ ! -d $ROTDIR ]; then mkdir -p $ROTDIR; fi        

#Set up forecast run directory:
 
if [ ! -d $DATA ]; then mkdir -p $DATA; fi
if [ ! -d $DATA/INPUT ]; then mkdir -p $DATA/INPUT; fi
if [ ! -d $DATA/restart ]; then mkdir -p $DATA/restart; fi
if [ ! -d $DATA/history ]; then mkdir -p $DATA/history; fi
#TODO: do we need OUTPUT or is everything in MOM6_OUTPUT? 
if [ ! -d $DATA/OUTPUT ]; then mkdir -p $DATA/OUTPUT; fi
if [ ! -d $DATA/MOM6_OUTPUT ]; then mkdir -p $DATA/MOM6_OUTPUT; fi
if [ ! -d $DATA/MOM6_RESTART ]; then mkdir -p $DATA/MOM6_RESTART; fi
if [ ! -d $DATA/DATM_INPUT ]; then mkdir -p $DATA/DATM_INPUT; fi

# Go to Run Directory (DATA)         
cd $DATA 

######################################################################
######################################################################
# 2. Inputs:                                                         #
#                                                                    # 
# 2.1 input.nml (MOM6/FMS))                                          #
# 2.2 diag_table/data_table (MOM6/FMS)                               #
# 2.3 model_configure (NEMS/DATM))                                   # 
# 2.4 nems_configure (NEMS)                                          #
# 2.5 MOM_input/MOM_override (MOM6)                                  #
# 2.6 CICE input (CICE5)                                             #
# 2.7 DATM datm_data_table (DATM)                                    #
#                                                                    #
# DATM input variable documentation:                                 #
# https://github.com/NOAA-EMC/NEMSdatm/wiki/DATM-Input-File-Descriptions #
######################################################################
######################################################################

######################################################################
# 2.1 input.nml                                                      #
######################################################################

#Input.nml is an FMS file used by both FV3 and MOM6 
echo "creating input.nml"

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
# 2.2 diag_table and data_table                                      #
######################################################################

# diag_table is an FMS (FV3, MOM6) input file that determines outputs 
echo "Creating diag_table and data_table"

# build the diag_table with the experiment name and date stamp
cat > diag_table << EOF
MOM6 Forecast
$SYEAR $SMONTH $SDAY $SHOUR 0 0
EOF
cat $DIAG_TABLE >> diag_table

cp $TEMPLATEDIR/data_table.IN $DATA/data_table

######################################################################
# 2.3 model_configure                                                #
######################################################################

#Model_configure is used by the NEMS driver, FV3 and DATM to get inputs
echo "Creating model_configure"

# More info on variables: https://vlab.ncep.noaa.gov/redmine/projects/emc_nemsdatacomps/wiki/Input_File_Descriptions#model_configure

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
nfhout:                    ${NFHOUT} 
filename_base:             ${DATM_FILENAME_BASE}
EOF

######################################################################
# 2.4 nems_configure                                                 #
######################################################################

# nems.configure is used by NEMS driver  
echo "Creating nems.configure file"

##TODO: Someday need to add cold start capability, keeping simple for now 
#Determine values of variables based one if mediator cold start or not
#if [[ $inistep = "medcold" ]]; then
#  #cold mediator restart 
#  restart_interval_write=0
#  confignamevarfornems="medcold_atm_ocn_ice"
#  medcoldstart=true    
#else
  restart_interval_write=${restart_interval:-86400}    # Interval in seconds to write restarts
  confignamevarfornems="med_atm_ocn_ice"
  medcoldstart=false
#fi

#Calculate bounds based on resource PETS
med_petlist_bounds=${med_petlist_bounds:-"0 $(( $MEDPETS-1 ))"}
atm_petlist_bounds=${atm_petlist_bounds:-"0 $(( $ATMPETS-1 ))"}
ocn_petlist_bounds=${ocn_petlist_bounds:-"$ATMPETS $(( $ATMPETS+$OCNPETS-1 ))"} 
ice_petlist_bounds=${ice_petlist_bounds:-"$(( $ATMPETS+$OCNPETS )) $(( $ATMPETS+$OCNPETS+$ICEPETS-1 ))"} 

# Copy the selected template into run directory
rm -f $DATA/nems.configure
cp $TEMPLATEDIR/nems.configure.${confignamevarfornems}.IN tmp1
# Replace values in template
sed -i -e "s;@\[med_model\];$medmod;g" tmp1
sed -i -e "s;@\[atm_model\];$atmmod;g" tmp1
sed -i -e "s;@\[med_petlist_bounds\];$med_petlist_bounds;g" tmp1
sed -i -e "s;@\[atm_petlist_bounds\];$atm_petlist_bounds;g" tmp1
if [ $cplflx = .true. ]; then
   sed -i -e "s;@\[ocn_model\];$ocnmod;g"  tmp1
   sed -i -e "s;@\[ocn_petlist_bounds\];$ocn_petlist_bounds;g" tmp1
   sed -i -e "s;@\[DumpFields\];$DumpFields;g" tmp1
   sed -i -e "s;@\[coldstart\];$medcoldstart;g"   tmp1
   sed -i -e "s;@\[restart_interval\];$restart_interval_write;g" tmp1
   sed -i -e "s;@\[CPL_SLOW\];$CPL_SLOW;g" tmp1
   sed -i -e "s;@\[CPL_FAST\];$CPL_FAST;g" tmp1
fi
if [ $cplice = .true. ]; then
   sed -i -e "s;@\[ice_model\];$icemod;g" tmp1
   sed -i -e "s;@\[ice_petlist_bounds\];$ice_petlist_bounds;g" tmp1
fi
# Rename and move to nems.configure 
mv tmp1 nems.configure

######################################################################
# 2.5 MOM_input and MOM_override                                     #
######################################################################

echo "Creating MOM_input and MOM_override"

# Copy the ice template into run directory
cp $TEMPLATEDIR/MOM_input_template tmp1
# Replace values in template
sed -i -e "s;DT_THERM_MOM6;${DT_THERM_MOM6};g" tmp1
sed -i -e "s;DT_DYNAM_MOM6;${DT_DYNAM_MOM6};g" tmp1
# Rename to proper input ice input name
mv tmp1 $DATA/INPUT/MOM_input

# TODO: Append to template MOM_override? My (Guillaume) opinion is to keep it empty 
#       in the static files, and populate it from scratch as needed. 
#cp $TEMPLATEDIR/MOM_override $DATA/INPUT/MOM_override
echo 'RESTART_CHECKSUMS_REQUIRED = False' > $DATA/INPUT/MOM_override
cat $DATA/INPUT/MOM_override

######################################################################
# 2.6 CICE input                                                     #
######################################################################

echo "Create CICE input files" 
# parsing namelist of CICE (ice_in) 

# info on restarting CICE model is here: 
#  https://vlab.ncep.noaa.gov/redmine/projects/emc_fv3-mom6-cice5/wiki/Restarting_the_coupled_model#CICE5

FRAZIL_FWSALT=${FRAZIL_FWSALT:-".true."}
tr_pond_lvl=${tr_pond_lvl:-".true."} # Use level melt ponds tr_pond_lvl=true

# restart_pond_lvl (if tr_pond_lvl=true):
#   -- if true, initialize the level ponds from restart (if runtype=continue) 
#   -- if false, re-initialize level ponds to zero (if runtype=initial or continue)  
if [ -d $nextic ]; then
  #continuing run "hot start" 
  RUNTYPE='continue'
  USE_RESTART_TIME='.false.'
  restart_pond_lvl=${restart_pond_lvl:-".true."}    
else 
  #using cold start IC
  RUNTYPE='initial'
  USE_RESTART_TIME='.false.'
  restart_pond_lvl=${restart_pond_lvl:-".false."}
fi

dumpfreq_n=${dumpfreq_n:-"${restart_interval}"} 
dumpfreq=${dumpfreq:-"s"} #  "s" or "d" or "m" for restarts at intervals of "seconds", "days" or "months"

iceres=${iceres:-"mx025"}
ice_grid_file=${ice_grid_file:-"grid_cice_NEMS_${iceres}.nc"}
ice_kmt_file=${ice_kmt_file:-"kmtu_cice_NEMS_${iceres}.nc"}

#TODO iceic name... this might need to be update? 
iceic='cice5_model.res.nc'


#TODO: nhour is not getting propagated from workflow/patforms/hera.yaml for some reason..
NWPROD="/scratch1/NCEPDEV/global/glopara"
NHOUR="$NWPROD/git/NCEPLIBS-prod_util/v1.1.0/exec/nhour"

echo "NHOUR is ${NHOUR}"
echo "DT_CICE is $DT_CICE"
echo "CDATE is $CDATE" 
echo "SYEAR is $SYEAR" 

# Calculated variables for ice_in: 
stepsperhr=$((3600/${DT_CICE}))
echo "stepsperhr is $stepsperhr"
nhours=$(${NHOUR} ${CDATE} ${SYEAR}010100)
istep0=$((nhours*stepsperhr))
npt=$((FHMAX*$stepsperhr))      # Need this in order for dump_last to work

# Copy the ice template into run directory
cp $TEMPLATEDIR/ice_in_template tmp1
# Replace values in template
sed -i -e "s;YEAR_INIT;${SYEAR};g" tmp1
sed -i -e "s;ICE_IC_NAME;${iceic};g" tmp1
sed -i -e "s;NPT;${npt};g" tmp1
sed -i -e "s;ISTEP0;${istep0};g" tmp1
sed -i -e "s;DT_CICE;${DT_CICE};g" tmp1
sed -i -e "s;NPROC_ICE;${ICEPETS};g" tmp1
sed -i -e "s;RUNTYPE;${RUNTYPE};g" tmp1
sed -i -e "s;USE_RESTART_TIME;${USE_RESTART_TIME};g" tmp1
sed -i -e "s;DUMPFREQ_N;${dumpfreq_n};g" tmp1
sed -i -e "s;DUMPFREQ;${dumpfreq};g" tmp1
sed -i -e "s;FRAZIL_FWSALT;${FRAZIL_FWSALT};g" tmp1
sed -i -e "s;TR_POND_LVL;${tr_pond_lvl};g" tmp1
sed -i -e "s;RESTART_POND_LVL;${restart_pond_lvl};g" tmp1
sed -i -e "s;ICE_GRID_FILE;${ice_grid_file};g" tmp1
sed -i -e "s;ICE_KMT_FILE;${ice_kmt_file};g" tmp1

# Rename to proper input ice input name
mv tmp1 ice_in 

######################################################################
# 2.7 datm_data_table (DATM)                                         #
######################################################################

# Copy the ice template into run directory
cp $TEMPLATEDIR/datm_data_table.IN tmp1
# Replace values in template
#sed -i -e "s;SOMEVAR;${SOMEVAR};g" tmp1

# Rename to proper input ice input name
mv tmp1 $DATA/datm_data_table

######################################################################
######################################################################
# 3. Link fix files                                                  #
#                                                                    #
# 3.1 Link DATM forcing files                                        #
# 3.2 Link MOM6 ICs, inputs and fix files                            #
# 3.3 Link CICE5 ICs, inputs and fix files                           #
#                                                                    #
######################################################################
######################################################################

######################################################################
# 3.1 Link DATM  inputs (ie forcing files)                           #
######################################################################

#TODO: This should be some loop through CDATE-> CDATE+ FORECAST length 
#and get input from either CFSR or GEFS or Whatever... 
#Currently assumes you only need the month of DATM input for IC date

# DATM forcing file name convention is ${DATM_FILENAME_BASE}.$YYYYMMDDHH.nc 
echo "Link DATM forcing files"
DATMINPUTDIR="/scratch2/NCEPDEV/marineda/DATM_INPUT/CFSR/${SYEAR}${SMONTH}"
ln -sf ${DATMINPUTDIR}/${DATM_FILENAME_BASE}*.nc $DATA/DATM_INPUT/

######################################################################
# 3.2 Link MOM6 fix files                                            #
######################################################################

echo "Link MOM6 fix files" 
ln -sf $FIXmom/* $DATA/INPUT/

######################################################################
# 3.3 Link CICE5 fix files                                           #
######################################################################

echo "Link CICE fixed files"
ln -sf $FIXcice/${ice_grid_file} $DATA/
ln -sf $FIXcice/${ice_kmt_file} $DATA/

######################################################################
######################################################################
# 4. Copy restarts/ICs                                               #
#                                                                    #
# 4.1 Copy Mediator restart files                                    #
# 4.2 Copy MOM6 restarts/IC                                          #
# 4.3 Copy CICE5 restart/IC                                          #
# 4.4 Remove NEXT_IC Dir                                             #
#                                                                    #
######################################################################
######################################################################

######################################################################
# 4.1  Copy Mediator restart files                                   #
######################################################################

echo "Copy mediator restart files" 

# Copy mediator restart files to RUNDIR       
if [ $inistep = 'cold' ]; then
  echo "mediator cold start run sequence... error currently not set up for this"
else
  if [ -d $nextic ]; then 
    #cp $ROTDIR/$CDUMP.$PDY/$cyc/mediator_* $DATA/
    cp $nextic/mediator_* $DATA/
  else 
    if [ $NEARESTCDATE = '2011100100' ]; then
      echo "Copying mediator restarts for $NEARESTCDATE from regtest area"
      ICSDIR="/scratch1/NCEPDEV/nems/emc.nemspara/RT/DATM-MOM6-CICE5/master-20191106/MEDIATOR_2011100100"
      cp $ICSDIR/mediator* $DATA/
    else 
       echo "ERROR:  You need to generate mediator restarts for this from a cold-mediator run sequence"
    fi 
  fi 
fi

######################################################################
# 4.2 Copy MOM6 IC                                                   #
######################################################################
#TODO: coordinate with DA -- does this get copied over somewhere else? 

echo "Copy MOM6 ICs" 

# Copy MOM6 ICs
if [ -d $nextic ]; then
    # Get IC from previous cycle
    ##cp ../NEXT_IC/cice_bkg.nc $RUNCDATE/INPUT_MOM6/cice_bkg.nc
    cp $nextic/MOM*.nc $DATA/INPUT/
else 

  echo "CICE5 IC is being copied from benchmark area for CDATE $CDATE" 
  echo "Note these only exist for the 01 and 15 ths of every month" 
  #TODO: hardcoded IC date for first date for benchmark 
  ICSDIR=/scratch2/NCEPDEV/climate/Bin.Li/S2S/FROM_HPSS/
  cp -pf $ICSDIR/$NEARESTCDATE/mom6_da/MOM*nc $DATA/INPUT/
fi

######################################################################
# 4.3 Copy CICE5 ICs                                                 #
######################################################################
#TODO: coordinate with DA -- does this get copied over somewhere else?

echo "Copy CICE5 ICs" 

if [ -d $nextic ]; then
  #cp $ROTDIR/$CDUMP.$PDY/$cyc/$iceic $DATA/restart/
  cp $nextic/restart/* $DATA/restart/
else 
  echo "CICE5 IC is being copied from benchmark area for CDATE $CDATE" 
  echo "Note these only exist for the 01 and 15 ths of every month" 
  #first IC: generated from CFSv2
  #TODO: hardcoded IC date for first date for benchmark
  ICSDIR=/scratch2/NCEPDEV/climate/Bin.Li/S2S/FROM_HPSS/
  cp -p $ICSDIR/$NEARESTCDATE/cice5_model_0.25.res_$NEARESTCDATE.nc $DATA/$iceic
  #TODO: could grab cpc instead of cfsr for this IC (need cice namelist changes for cpc)
  #cp -p $ICSDIR/$CDATE/cpc/cice5_model_0.25.res_$CDATE.nc ./cice5_model.res_$CDATE.nc
fi

######################################################################
# 4.4 Remove NEXT_IC DIR                                             #
######################################################################

#echo "removing NEXT_IC DIR"

mv $nextic $keepic

######################################################################
#   End of prep_forecast.sh                                          #
######################################################################
echo "End of prep_forecast.sh"
