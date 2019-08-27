#!/bin/bash
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
#set -x

echo
echo '#=================================================================#'
echo '# prep_BKG_DATE_yaml.sh starts                                    #'
echo '#                                                                 #'
echo

while getopts "i:d:" opt; do
   case $opt in
      i) yamlfile=("$OPTARG");;
      d) bck_date=(${OPTARG});;
   esac
done
shift $((OPTIND -1))

cd ${RUNDIR}

if [ -f "$yamlfile" ]; then

   sed -i "s/BKG_DATE/${bck_date}/g"  ${yamlfile}

else

   echo "ERROR: There is not "$yamlfile "exiting..."
   exit

fi

echo
echo '#                                                                 #'
echo '# prep_BKG_DATE_yaml.sh ends                                      #'
echo '#=================================================================#'
echo
