# Introduction
The following five steps will guide you through the process of cloning, building and 
running the GODAS workflow. 

During this process, three directories will be created:
- CLONE_DIR    : The directory where the system is cloned, user defined path

- PROJECT_DIR  : The directory where the workflow is deployed, user defined path

- RUNCDATE     : The directory where the system runs, optionally defined by the user.


# Clone godas
0. `set CLONE_DIR=PATH/OF/YOUR/CHOICE`
1. `git clone https://github.com/NOAA-EMC/godas.git $CLONE_DIR`
2. `cd $CLONE_DIR`
3. `git submodule update --init --recursive`

# Clone model and soca-bundle (bundle of repositories necessary to build soca)

0. `sh $CLONE_DIR/src`
1. `sh checkout.sh godas`

# Build the model: 
0. `sh $CLONE_DIR/src`
1. `sh build_ufs_godas.sh`

# Preparing the workflow
0. Create the directory that the workflow will be deployed:
   `mkdir -p PROJECT_DIR`
1. `cd $CLONE_DIR/workflow` 
2. Create/Edit `user.yaml` based on `user.yaml.default` \
   `cp user.yaml.default user.yaml` \
   edit `user.yaml` \
Update the following fields in the `user.yaml` and save the file \
   `PROJECT_DIR: !error Please select a project directory.` \
   `FIX_SCRUB: False` \
   `SCRUB: none # Please select a scrub space when FIX_SCRUB is True` \
   `user_email: none` \
   `cpu_project: !error Please select your cpu project` \
   `hpss_project: !error Please select your hpss project`

If the variable FIX_SCRUB is true, the RUNCDATE directory will be created in the SCRUB.
Otherwise the RUNCDATE is created automatically at stmpX directory of the user. 

3. `cd $CLONE_DIR/workflow/CROW`
4. Setup the workflow: \
   Select a name for the workflow path, e.g. workflowtest001 and a case, e.g. the 3dvar_only_exp: \
   `./setup_case.sh -p HERA -f ../cases/3dvar_only_exp.yaml workflowtest001`
   
   This will setup the workflow in `workflowtest001` for the 3DVAR case on Hera.
   
5. Read output and run suggested command. Should be similar to: \
   `./make_rocoto_xml_for.sh PROJECT_DIR/workflowtest001` 
# Building the soca-bundle 
0. Create the build directory for SOCA
   `mkdir -p $CLONE_DIR/build` \
   `cd $CLONE_DIR/build`
1. Load the JEDI modules \
   `module purge` \
   `module use -a /scratch2/NCEPDEV/marine/marineda/modulefiles` \
   `module load jedi-intel-17.0.5.239`
2. Clone all the necessary repositories to build soca \
   `ecbuild --build=release -DMPIEXEC=$MPIEXEC -DMPIEXEC_EXECUTABLE=$MPIEXEC -DBUILD_ECKIT=YES ../src/soca-bundle`
3. `make -j12`
4. Unit test the build \
   `salloc --ntasks 12 --qos=debug --time=00:30:00 --account=marine-cpu` \
   `ctest`
 5. Change the soca-config branch \
    The yaml files that configure the DA experiments live inside of the soca-config repository. For example, to checkout the feature branch for the 3DVAR: \
   `cd $CLONE_DIR/soca-bundle/soca-config` \
   `git checkout feature/emc-3dvar` \
    or alternatively, checkout your own branch or the branch you need to test with.

# Running the workflow
Assumption all the subsystems have been compiled.
The workflow can interactively as shown at step 3. below or as cronjob.

1. Go into the test directory \
   `cd PROJECT_DIR/workflowtest001`
2. Load module rocoto \
   `module load rocoto`
3. Start rocoto \
   `rocotorun -w workflow.xml -d workflow.db`
4. Check status \
   `rocotorun -w workflow.xml -d workflow.db & rocotostat -v 10 -w workflow.xml -d workflow.db`
5. Repeat step 4 until all jobs are completed. 

# Check the run and the results
0. The log files of your experiment are at 
`PROJECT_DIR/workflowtest001/log/`
1. The the setup files and outputs of the experiment are at
`${RUNCDATE}` 
