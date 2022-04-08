Use the following api to check missing files or plotting number of obs and min/max value:
python godas_obssanitycheck.py -f adt_c2 -s 20190101 -e 20190321 -p /path/to/file -q frequency 

It requires file_descriptor, such as adt_c2, adt_j3 etc. and also start and end date, default frequency is daily
