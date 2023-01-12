mkdir -p plots
yr=$1
ddir=/work/noaa/ng-godas/marineda/validation/GIOMAS/$yr
ddir=.
python interpolate_giomas_monthly.py -g soca_gridspec.nc -m 8 9 10 11 -s ${ddir}/heff.H${yr}.nc -o heff.G${yr}.nc -p True -r True -d plot_giomas

