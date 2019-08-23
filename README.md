# Clone godas
1. `git clone --recursive https://github.com/NOAA-EMC/godas.git` godas\
2. `cd godas`
2. `git submodule update --init --recursive` \

# Preparing the workflow
1. `cd godas/workflow` \
2. Create/Edit `user.yaml` based on `user.yaml.default`
3. `cd CROW`
4. `sh setup_case.sh -f ../cases/3dvar_only_exp.yaml workflowtest001`
5. Read output and run suggested command. Should be similar to: \
   `./make_rocoto_xml_for.sh /path/to/somewhere/workflowtest001` \
6. Go into the test directory
   `cd /path/to/somewhere/workflowtest001`
7. Start rocoto
   `rocotorun -w workflow.xml -d workflow.db`
8. Check status
   `rocotostat -w workflow.xml -d workflow.db & rocotostat -v 10 -w workflow.xml -d workflow.db`

# Building the soca-bundle on Theia (should that be part of the workflow?)

1. Load the JEDI modules \
   `module use -a /contrib/da/modulefile` \
   `module load jedi`
2. Building path TBD: `cd build`
3. Clone all the necessary repository to build soca \
   `ecbuild --build=release -DMPIEXEC=$MPIEXEC -DMPIEXEC_EXECUTABLE=$MPIEXEC -DMPIEXEC_MAX_NUMPROCS=24 ../src/soca-bundle`
4. `make -j<n>`
5. Unit test the build \
   `ctest`
