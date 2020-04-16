#! /bin/csh

cd $CLONE_DIR/src/letkf  
git submodule update --init --recursive  
mkdir -p $CLONE_DIR/build/letkf
cd $CLONE_DIR/build/letkf
source $CLONE_DIR/src/letkf/config/env.$MACHINE_ID
cmake -DNETCDF_DIR=$NETCDF $CLONE_DIR/src/letkf 
make -j2
ln -fs $CLONE_DIR/build/letkf/bin/letkfdriver $CLONE_DIR/build/bin/letkfdriver

