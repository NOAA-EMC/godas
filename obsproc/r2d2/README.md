# emc_obsdb
Wrapper to JCSDA tools to manage the EMC marine observation database. 
You will need to load the jedi modules and use the version of R2D2 that is 
currently used in soca-science. The simplest way to get have access to all the dependencies 
is to source the appropriate machine files in soca-science.

0 - To test/build
``` console
ecbuild ../godas/obsproc/r2d2/
make
ctest
```

1 - Set R2D2_CONFIG to the desired yaml file
For examplem on Orion:
``` console
export R2D2_CONFIG=.../src/r2d2_config.orion.yaml
```

2 - Example: Populating the database using the old soca format as source for absolute dynamic topography
``` console
ln -s <path/to/old/ioda/observations/obs> obs
./soca_store_obs.py --start 20150101 --end 20150101 --source ./obs --provider jcsda_soca --experiment benchmark_v2 --obstype adt --platforms 3a c2 j2 j3 sa
```
