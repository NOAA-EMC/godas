# Clone godas
1. `git clone --recursive https://github.com/NOAA-EMC/godas.git godas`
2. `cd godas`
3. `git submodule update --init --recursive` \

# Preparing the workflow
1. `cd workflow` 
2. Create/Edit `user.yaml` based on `user.yaml.default`
   `cp user.yaml.default user.yaml`
   `vi user.yaml`
Update the following fields in the `user.yaml` and save the file
   `PROJECT_DIR: !error Please select a project directory.
   user_email: none
   cpu_project: !error Please select your cpu project
   hpss_project: !error Please select your hpss project`
3. `cd CROW`
4. Setup the workflow as follows; select a name for the workflow path, e.g. workflowtest001
   and a case, e.g. the 3dvar_only_exp:
   `sh setup_case.sh -f ../cases/3dvar_only_exp.yaml workflowtest001`
   
   Note for Hera: 
   `./setup_case.sh -f ../cases/3dvar_only_exp.yaml workflowtest001`
   
5. Read output and run suggested command. Should be similar to:
   `./make_rocoto_xml_for.sh PROJECT_DIR/workflowtest001` 
 
# Running the workflow
Assumption all the subsystems have been compiled

1. Go into the test directory
   `cd PROJECT_DIR/workflowtest001`
2. Load module rocoto
   `module load rocoto`
3. Start rocoto
   `rocotorun -w workflow.xml -d workflow.db`
4. Check status
   `rocotostat -v 10 -w workflow.xml -d workflow.db & rocotostat -v 10 -w workflow.xml -d workflow.db`

# Building the soca-bundle on Theia 
(TODO: should that be part of the workflow?)

0. `cd [...]/godas/src/soca-bundle`
1. Load the JEDI modules 
   `module use -a /contrib/da/modulefiles` 
   `module load jedi`
2. Building path TBD: `cd [...]/godas/build`
3. Clone all the necessary repository to build soca 
   `ecbuild --build=release -DMPIEXEC=$MPIEXEC -DMPIEXEC_EXECUTABLE=$MPIEXEC -DMPIEXEC_MAX_NUMPROCS=24 ../src/soca-bundle`
4. `make -j<n>`
5. Unit test the build 
   `ctest`
