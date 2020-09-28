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

&fms_nml
            clock_grain='ROUTINE'
            clock_flags='NONE'
            domains_stack_size = 5000000
            stack_size =0
/
 &MOM_input_nml
         output_directory = 'OUTPUT/',
         input_filename = '$restart'
         restart_input_dir = 'RESTART_IN/',
         restart_output_dir = 'RESTART/',
         parameter_filename = 'MOM_input',
                              'MOM_override' /

EOF
