# Introduction
The following five steps will guide you through the process of cloning, building and running the GODAS workflow. 

The instructions below are for csh and bash. 

During this process, three directories will be created:
- CLONE_DIR    : The directory where the system is cloned, user defined path.

- MACHINE_ID   : The name of the HPC that the system is installed, currently supported hera and orion

- BUILD_COMPILER     : Set the compiler that you would like to use. The options are intel18(Hera) or intel19 (Orion), depending on the machine. 

- EXPROOT  : The directory where the EXPDIR is created, storing workflow configuration files, user defined path.

- COMROOT  : The directory where input and output of jobs are stored, user defined path.

- DATAROOT : The directory where each job runs, user defined path.

- RUNCDATE     : The directory where the system runs, optionally defined by the user

# Clone GODAS
0. `setenv CLONE_DIR PATH/OF/YOUR/CHOICE` or `export CLONE_DIR=PATH/OF/YOUR/CHOICE`
1. `setenv MACHINE_ID hera` or `export MACHINE_ID=orion`
   `setenv BUILD_COMPILER intel18` or `export BUILD_COMPILER=intel19` 

2. `git clone https://github.com/NOAA-EMC/godas.git $CLONE_DIR`

   If automatic system build/test is preferred, see the instructions [here](./test/README.md). Otherwise, steps to manually set up the GODAS and test cases are as follows:

3. `cd $CLONE_DIR`
4. `git submodule update --init --recursive` 

# Clone and build model

0. `cd $CLONE_DIR/src`
1. `sh checkout.sh godas`
2. `sh link.sh godas $MACHINE_ID`
3. `sh build_DATM-MOM6-CICE5.sh`

# Clone the soca-bundle and build SOCA
The bundle of repositories necessary to build SOCA 

1. Create the build directory for SOCA
   `mkdir -p $CLONE_DIR/build` \
   `cd $CLONE_DIR/build`
2. Load the JEDI modules \
   `module purge` \
   `source  $CLONE_DIR/modulefiles/$MACHINE_ID.$BUILD_COMPILER` \
   `source  $CLONE_DIR/modulefiles/$MACHINE_ID.setenv` \
   `module list` 

3. Clone all the necessary repositories to build SOCA: SOCA develop and stable nightly branches can be cloned in building GODAS system.

   'git clone --branch release/stable-nightly https://github.com/JCSDA/soca-bundle.git $CLONE_DIR/src/soca-bundle'

   'git clone https://github.com/JCSDA/soca-bundle.git $CLONE_DIR/src/soca-bundle'

    Hera: 'ecbuild --build=release -DMPIEXEC_EXECUTABLE=`which srun` -DMPIEXEC_NUMPROC_FLAG="-n" -DBUILD_ECKIT=ON -DBUILD_CRTM=OFF $CLONE_DIR/src/soca-bundle'

    Orion: `ecbuild --build=release -DBUILD_ECKIT=ON -DBUILD_METIS=ON -DBUILD_CRTM=ON $CLONE_DIR/src/soca-bundle`

4. `make -j12`
5. Unit test the build \
   `salloc --ntasks 12 --qos=debug --time=00:30:00 --account=marine-cpu` \
   `ctest`
6. Change the soca-config branch \
    The yaml files that configure the DA experiments live inside of the soca-config repository. For example, to checkout the feature branch for the 3DVAR: \
   `cd $CLONE_DIR/src/soca-bundle/soca-config` \
   `git checkout develop` \
    or alternatively, checkout your own branch or the branch you need to test with.

# Clone and build the UMD-LETKF
For detail instructions on how to install LETKF at any machine, see the [LETKF repository](https://github.com/NOAA-EMC/UMD-LETKF). For GODAS, just run the following script:
`sh $CLONE_DIR/src/letkf_build.sh`, which executes the following build procedures.

'mkdir -p $CLONE_DIR/build/letkf'

'git clone --recursive https://github.com/NOAA-EMC/UMD-LETKF.git $CLONE_DIR/src/letkf'

'cd $CLONE_DIR/src/letkf'

'git submodule update --init --recursive'

'cd $CLONE_DIR/build/letkf'

'module purge'

'source $CLONE_DIR/src/letkf/config/env.$MACHINE_ID'

'cmake -DNETCDF_DIR=$NETCDF $CLONE_DIR/src/letkf'

'make -j2'

'ln -fs $CLONE_DIR/build/letkf/bin/letkfdriver $CLONE_DIR/build/bin/letkfdriver'x

# Copy the mom6-tools.plot to the bin
0. cp $CLONE_DIR/src/mom6-tools.plot/*.py $CLONE_DIR/build/bin/ 

# Preparing the workflow
0. Create the directory that the workflow will be deployed:
   `mkdir -p EXPROOT`
1. `cd $CLONE_DIR/workflow` 
2. Create/Edit `user.yaml` based on `user.yaml.default` \
   `cp user.yaml.default user.yaml` \
   edit `user.yaml` \
Update the following fields in the `user.yaml` and save the file \
   `EXPROOT: !error Please select a project directory.` \
   `FIX_SCRUB: True` \
   `COMROOT: !error Please select your COMROOT directory` \
   `DATAROOT: !error Please select your DATAROOT directory` \

   `user_email: none` \
   `cpu_project: !error Please select your cpu project` \
   `hpss_project: !error Please select your hpss project`

If the variable FIX_SCRUB is true, the RUNCDATE directory will be created in the COMROOT.
Otherwise the RUNCDATE is created automatically at stmpX directory of the user. 

3. `cd $CLONE_DIR/workflow/CROW`
4. Setup the workflow: \
   Select the machine name in upper case, e.g. HERA, a name for the workflow path, e.g. workflowtest001 and a case, e.g. the 3DVAR: \
   `./setup_case.sh -p HERA ../cases/3dvar.yaml workflowtest001`
   
   This will setup the workflow in `workflowtest001` for the 3DVAR case on Hera.
 
   Available cases:
   1. 3dvar.yaml
   2. letkf_only_exp.yaml
   3. fcst_only.yaml
   4. hofx3d_only.yaml
 
   Note: Each case files point to a corresponding layout file at $CLONE_DIR/workflow/layout. 

5. Read output and run suggested command. Should be similar to: \
   `./make_rocoto_xml_for.sh EXPROOT/workflowtest001` 

# Running the workflow
Assumption: All the subsystems have been compiled.
The workflow can interactively as shown at step 3. below or as cronjob.

1. Go into the test directory \
   `cd EXPROOT/workflowtest001`
2. Load module rocoto \
   `module load rocoto`
3. Start rocoto \
   `rocotorun -w workflow.xml -d workflow.db`
4. Check status \
   `rocotorun -w workflow.xml -d workflow.db & rocotostat -v 10 -w workflow.xml -d workflow.db` \
   Or you could use "rocoto_viewer.py". Your terminal window needs to be wider than 125 chars \
   `rocotorun -w workflow.xml -d workflow.db `\
   `python rocoto_viewer.py -w workflow.xml -d workflow.db`
5. Repeat step 4 until all jobs are completed. 

# Updating resource settings of the workflow
resource_sum.yaml inside EXPDIR serves as a central place of resource settings. Changing the values(PET count, wall time) inside it and rerun CROW with the -f option could change the resource setting for this experiment.

./setup_case.sh -p HERA ../cases/3dvar.yaml test3dvar
./make_rocoto_xml_for.sh /scratch1/NCEPDEV/global/Jian.Kuang/expdir/test3dvar

There will be a resource_sum.yaml in EXPDIR named test3dv. Changing resource allocation values (time, npe) there and redo CROW:

./setup_case.sh -p HERA -f ../cases/3dvar.yaml test3dv
./make_rocoto_xml_for.sh /scratch1/NCEPDEV/global/Jian.Kuang/expdir/test3dvar

You could see the resources being updated in workflow.xml as well as config files.

# Check the run and the results
0. The log files of your experiment are at 
`EXPROOT/workflowtest001/log/`
1. The the setup files and outputs of the experiment are at
`${RUNCDATE}` 

# Configuration Options
The user can change a limited set of parameters in the DA cases availabe under `.../cases/`. 

--------------------------------------------------------------
The yaml code snipet below shows the test example for the 3DVAR given in ./cases/3dvar.yaml

``` yaml
case:
  settings:
    SDATE: 2011-10-01t12:00:00   # Start Date of the experiment
    EDATE: 2011-10-02t12:00:00   # End         "         "
    godas_cyc: 1                 # selection of godas DA window: 1(default)- 24h; 
                                 #                               2 - 12h; 
                                 #                               4 - 6h
                                 # NOTE: ONLY OPTION 1 IS CURRENTLY SUPPORTED.                                 
    resolution: Ocean025deg      # Other options: Ocean3deg, Ocean1deg, Ocean025deg
    forcing: CFSR                # CFSR or GEFS. It supports any forcing that satisfies the DATM-MOM6-CICE5 model and its setup

  da_settings:
    FCSTMODEL: MOM6CICE5     # Specifies the forecast model, the other option is MOM6solo
    NINNER: 5              # Number of inner iteration in conjugate gradient solver
    # Observation switches
    DA_SST: True    # Sea surface temperature
    DA_TS: True     # T & S Insitu profiles 
    DA_ADT: True    # Absolute dynamic topography
    DA_ICEC: True   # Seaice fraction
    NO_ENS_MBR: 2   # Size of ensemble, e.g. two members.
    GROUPS: 2       # No of groups to run the ensemble, in this case, each member runs in a different group.

  places:
    workflow_file: layout/3dvar_only.yaml
```
The default is 1 member to 1 group (deterministic run).

--------------------------------------------------------------
The yaml code snipet below shows the test example for the hofx given in ./cases/hofx.yaml

``` yaml
case:
  settings:
    SDATE: 2011-10-01t12:00:00   # Start Date of the experiment
    EDATE: 2011-10-02t12:00:00   # End         "         "
    godas_cyc: 1                 # selection of godas DA window: 1(default)- 24h; 
                                 #                               2 - 12h; 
                                 #                               4 - 6h
                                 # NOTE: ONLY OPTION 1 IS CURRENTLY SUPPORTED.                                 
    resolution: Ocean025deg      # Other options: Ocean3deg, Ocean025deg
    FCSTMODEL: MOM6CICE5         # Specifies the forecast model, the other option is MOM6solo


  da_settings:
    # Observation switches
    DA_SST: False    # Sea surface temperature
    DA_TS: False     # T & S Insitu profiles 
    DA_ADT: True    # Absolute dynamic topography
    DA_ICEC: False   # Seaice fraction

  places:
    workflow_file: layout/hofx_only.yaml
    SOCA_ANALYSIS: "PATH/to/ANALYSIS" # Specifies the path to a completed 24h forecast model 

```
- SOCA_ANALYSIS is the run directory of a finished experiment. 
- The HofX output will be in the RUNCDATE/Data.


# Currently Supported Models/Resolutions/Da algorithms
| Cases | Forecast | 3DVAR | 3DHyb-EnVAR | LETKF |
| ------| :--------| :---- | :---------- |:----- |
| 3&deg;| :heavy_check_mark:MOM6solo | :heavy_check_mark: MOM6solo | :heavy_check_mark:MOM6solo | :soon:MOM6solo |
| 1&deg;| :heavy_check_mark:MOM6solo | :heavy_check_mark: MOM6solo | :heavy_check_mark:MOM6solo | :soon:MOM6solo |
| 0.25&deg;| :x:MOM6solo <br/> :heavy_check_mark:M6-C5|:x:MOM6solo <br/> :heavy_check_mark: M6-C5 | :x:MOM6solo <br/> :soon:M6-C5 | :x:MOM6solo <br/> :soon:M6-C5 |

:heavy_check_mark: Should work <br/>
:x: No implementation planned <br/>
:soon: Work in progress

# Post-processing Plot Options

0. scripts/post_plot.sh has been updated and included in rocoto workflow. In post processing run, sea ice fraction, SSH, SST, and time_mean figures will be created in $RUNCDATE/Figures directory. Additional offline post processing and plotting tools are available in src/mom6-tools directory: see the instruction [here](./src/mom6-tools.plot/README.md).

# SOCA-SCIENCE workflow

Please see [soca ufs wiki page](https://github.com/JCSDA/soca-science/wiki/soca-ufs) to conduct ufs (DATM-mom6-cice) model fcst & 3dvar runs with soca-science workflow. Currently only 0.25deg model works.
