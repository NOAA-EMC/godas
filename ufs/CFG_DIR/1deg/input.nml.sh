#!/bin/bash
set -eu

# This is a script file that generates the main input.nml file required by MOM for forecast runs.
# The following environment variables need to be set by the caller:
#  FCST_START_TIME   start date in any "date" util friendly format format
#  FCST_RESTART      1 if starting from a restart, otherwise 0
#  FCST_LEN          integration length, in hours
#  FCST_RST_OFST     time (hours) from beginning of forecast until when restart file is to be saved.


restart='n'
if [[ "$FCST_RESTART" == 1 ]]; then restart='r'; fi


cat <<EOF

 &diag_manager_nml
 /

 &ocean_solo_nml
            months = 0
            days   = 0
            hours  = $FCST_LEN,
            date_init = $(date -u "+%Y,%m,%d,%H" -d "${FCST_START_TIME}"),0,0,
            minutes = 0
            seconds = 0
            calendar = 'julian' /


 &MOM_input_nml
         output_directory = 'OUTPUT',
         input_filename = '$restart'
         restart_input_dir = 'RESTART_IN',
         restart_output_dir = 'RESTART',
         parameter_filename = 'MOM_input',
                              'MOM_override'
/

 &data_override_nml
 /

 &fms_io_nml
         fms_netcdf_restart=.true.
         threading_read='multi'
         max_files_w=100
         checksum_required=.false.
 /

 &fms_nml
       clock_grain='MODULE'
       domains_stack_size = 9552960
       clock_flags='SYNC' /

 &ice_albedo_nml
      t_range = 10. /

 &ice_model_nml
           /

 &monin_obukhov_nml
            neutral = .true. /

 &ocean_albedo_nml
      ocean_albedo_option = 5 /

 &sat_vapor_pres_nml
      construct_table_wrt_liq = .true.,
      construct_table_wrt_liq_and_ice = .true. /


EOF
