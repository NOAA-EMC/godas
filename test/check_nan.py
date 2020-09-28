#!/usr/bin/python

import sys
import netCDF4
import numpy as np

input_file = str(sys.argv[1])
output_file = str(sys.argv[2])

print ('input_file:', input_file)
print ('output_file:', output_file)

dset = netCDF4.Dataset(input_file, 'r+')
arr=dset['Salt'][:].data[:]
arr[np.isnan(arr)]=0.1

f = netCDF4.Dataset(output_file,'w')
f.createDimension('time',arr.shape[0])
f.createDimension('vt1',arr.shape[1])
f.createDimension('lat',arr.shape[2])
f.createDimension('lon',arr.shape[3])

v = f.createVariable('Salt',np.double,('time','vt1','lat','lon'))
v[:] = arr[:]

f.close()
dset.close()
