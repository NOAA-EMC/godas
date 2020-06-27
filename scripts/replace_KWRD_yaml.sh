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
# set -x

echo '#=================================================================#'
echo '#                   Replace_Keyword_yaml.sh starts                #'
echo '#                                                                 #'

while getopts "i:k:v:" opt; do
   case $opt in
      i) yamlfile=("$OPTARG");;
      k) keyword=("$OPTARG");;
      v) value=(${OPTARG});;
   esac
done
shift $((OPTIND -1))

cd ${RUNDIR}

if [ -f "$yamlfile" ]; then
   value=$(echo $value | sed -e "s#/#\\\/#g")
   sed -i "s/${keyword}/${value}/g"  ${yamlfile}
else
   echo "ERROR: There is not "$yamlfile "exiting..."
   #exit
fi

echo '#                                                                 #'
echo '#                    Replace_Keyword_yaml.sh                      #'
echo '#=================================================================#'
