#!/bin/ksh
#
# * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * #
#                       Unix Script Documentation
#
# Script Name        :
#
# Script Description :
#
# Details            :
#
# Author             :
#
# History Log        :
#
# * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * # * #
# set -x

echo '#=================================================================#'
echo '#                    prep_3denvar_yaml.sh starts                  #'
echo '#                                                                 #'

while getopts "i:m:d:n:" opt; do
   case $opt in
      i) yamlfile=("$OPTARG");;
      m) yamlmember=("$OPTARG");;
      d) RUNDIR=("$OPTARG");;
      n) Ne=("$OPTARG");;
   esac
done
shift $((OPTIND -1))

cd ${RUNDIR}

echo $membertemplate
for (( mbr=1; mbr<=${Ne} ; mbr++ )); do
    cp $yamlmember tmpl.txt
    sed -i "s/ENS_NUM/${mbr}/g" tmpl.txt
    sed -e '/ENSEMBLE_MEMBERS/ {' -e 'r tmpl.txt' -e 'd' -e '}' -i ${yamlfile}
    rm tmpl.txt
done

## Set date
sed -i "s/WINDOW_BEGIN/${window_begin}/g" ${yamlfile}
sed -i "s/WINDOW_LENGTH/${window_length}/g" ${yamlfile}
sed -i "s/BKG_DATE/${bkg_date}/g" ${yamlfile}
#
## Setup Jo cost function
##-----------------------

${ROOT_GODAS_DIR}/scripts/SetupJoCostFunction.sh \
      -i ${yamlfile}                             \
      -d $RUNDIR

echo '#                                                                 #'
echo '#                      prep_3denvar_yaml.sh ends                  #'
echo '#=================================================================#'
