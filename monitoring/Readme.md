To plot the fields one can use the python scripts: soca_plotfield.py

However, it is better to run a bash script to plot various variables on different dates.

The command is :
bash soca_plotfield.sh -x exp_name -v state_vector -s start_date -e end_date

for example:
bash soca_plotfield.sh -x EMC2 -v bkg -s 20210601 -e 20210601
bash soca_plotfield.sh -x EMC2 -v incr -s 20210601 -e 20210601

For obs_out, variables are sst, adt, salt, temp:
bash godas_plotobs.sh -x EMC3 -v sst -s 20210201 -e 20210202

This will use a python script named godas_plotobs.py

