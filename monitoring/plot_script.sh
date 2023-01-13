yr=$1
option=$2
ddir=/work/noaa/marine/jhossen/icethk_validation/data
if [[ ${option} == 'giomas' ]]; then
echo plotting $option ...
python interpolate_giomas_monthly.py -g ${ddir}/soca_gridspec_1d.nc -m 8 9  -s ${ddir}/heff.H${yr}.nc -o heff.G${yr}.nc -p True -r True -d plot_giomas
else
echo plotting $option ...
pdir=/work2/noaa/ng-godas/jhossen/PIOMAS
python interpolate_piomas_monthly.py -g ${ddir}/soca_gridspec_1d.nc -m 8 9  -s ${pdir}/heff.H${yr}.nc -o heff.P${yr}.nc -p True -r True -d plot_piomas
fi
