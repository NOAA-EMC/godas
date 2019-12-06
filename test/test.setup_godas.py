#!/usr/bin/env python3

import sys
import os, fnmatch
import os.path
import argparse
import yaml
import io
import shutil
import shlex, subprocess
import time
import pwd

def make_dir(path):
    if os.path.isdir(path): delete_dir(path) 
    try:
        os.makedirs(path)
    except OSError:
        print ("----- Creation of the directory %s failed" % path)
    else:
        print ("----- Successfully created the directory %s " % path)

def delete_dir(path):
    try:
        shutil.rmtree(path)
    except OSError:
        print ("----- Deletion of the directory %s failed" % path)
    else:
        print ("----- Successfully deleted the directory %s" % path)
        
def check_log(filename, string):
    if os.path.exists(filename):
        print("----- Checking log file:",filename)
        with open(filename) as myfile:
            if string in myfile.read():
                print("---------- Test successfully ran ----------")
            else:
                print("---------- Test run failed ----------------")
    else:
        print("----- log file not available to check:",filename)

def check_job_status(filename):
    jobcycle = []   #col 0
    jobtask  = []   #col 1
    jobstate = []   #col 3
    jobtries = []   #col 5
    with open(filename) as inf:
        for line in inf:
            parts = line.split() # split line into parts
            if len(parts) > 1:   # if at least 2 parts/columns        
                jobcycle.append(parts[0])
                jobtask.append(parts[1])
                jobstate.append(parts[3])
                jobtries.append(parts[5])

    alljobs_success = False
    count_success = 0
    count_submit  = 0
    count_qued    = 0
    lapse_time    = 60.*3

    for index in range(len(jobtask)):
        if jobstate[index] == 'SUCCEEDED':
            count_success += 1
            print (jobcycle[index],jobtask[index],jobstate[index],jobtries[index])
        if jobstate[index] == 'SUBMITTING':
            count_submit = 1
            lapse_time = 60.*6
            print (jobcycle[index],jobtask[index],jobstate[index],jobtries[index])
        if jobstate[index] == 'QUEUED':
            count_qued = 1
            lapse_time = 60.*6
            print (jobcycle[index],jobtask[index],jobstate[index],jobtries[index])
        if count_success == len(jobtask): alljobs_success = True

    return alljobs_success, lapse_time

if __name__ == '__main__':
    #1. Read directory paths, build/ctest option, and workflow name ------------
    try:  
        CLONE_DIR=os.environ.get('CLONE_DIR')
    except KeyError:
        print ("Please set the environment variable CLONE_DIR")
        sys.exit(1)

    with open('test.setup_godas.yaml') as input_file:
         input = yaml.load(input_file)
    PROJECT_DIR = input.get('PROJECT_DIR')
    WORKFLOW_NAME = input.get('WORKFLOW_NAME')
    SKIP_BUILD= input.get('SKIP_BUILD')

    USER = os.getenv('USER')

    path = os.getcwd()
    print ("----- Current work directory is %s" % path)

    if not SKIP_BUILD :    
        #1. Setup GODAS system at CLONE_DIR ------------------------------------
        print ('-----------Setup GODAS system at:',CLONE_DIR)
        os.chdir(CLONE_DIR)
        os.system("git submodule update --init --recursive")

        os.chdir(CLONE_DIR+"/src")
        os.system("sh checkout.sh godas")
        os.system("sh link.sh godas")
        os.system("sh build_DATM-MOM6-CICE5.sh") 

        #2. Clone and build soca system inside CLONE_DIR------------------------
        print ('-----------Clone and build SOCA system at:',CLONE_DIR)
        build_dir=CLONE_DIR+'/build'
        make_dir(build_dir); os.chdir(build_dir)

        subprocess.check_call(['bash','-c','module purge; source ../modulefiles/godas.main; module list; ecbuild --build=release -DMPIEXEC=$MPIEXEC -DMPIEXEC_EXECUTABLE=$MPIEXEC -DBUILD_ECKIT=YES -DBUILD_CRTM=OFF ../src/soca-bundle; make -j12'])

        soca_config_path=CLONE_DIR+'/src/soca-bundle/soca-config'
        os.chdir(soca_config_path)
        os.system('git checkout develop')
         
        #3. Clone and build the UMD-LETKF --------------------------------------
        os.chdir(CLONE_DIR)
        print ('-----------Clone and build the UMD-LETKF at:',CLONE_DIR)
        os.chdir(CLONE_DIR+"/src/letkf")
        os.system("git submodule update --init --recursive")
        make_dir(CLONE_DIR+"/build/letkf")
        os.chdir(CLONE_DIR+"/build/letkf")
        subprocess.check_call(['csh','-c','module purge; source ../../modulefiles/godas.main; source ../../src/letkf/config/env.hera; cmake -DNETCDF_DIR=$NETCDF ../../src/letkf; make -j2'])
 
        src_letkf=CLONE_DIR+'/build/letkf/bin/letkfdriver'
        dst_letkf=CLONE_DIR+'/build/bin/letkfdriver'
        os.symlink(src_letkf,dst_letkf)

    #4. Preparing the workflow and rocoto run case -----------------------------
    os.chdir(CLONE_DIR+"/workflow")
    shutil.copyfile('user.yaml.default', 'user.yaml')
    subprocess.call(["sed", "-i",  '/PROJECT_DIR/c\  PROJECT_DIR: '+PROJECT_DIR, "user.yaml"])
    subprocess.call(["sed", "-i",  '/cpu_project/c\  cpu_project: marine-cpu', "user.yaml"])
    subprocess.call(["sed", "-i",  '/hpss_project/c\  hpss_project: emc-marine', "user.yaml"])

    if os.path.isdir(PROJECT_DIR): delete_dir(PROJECT_DIR)
    make_dir(PROJECT_DIR)
    user_id=pwd.getpwuid( os.getuid() ).pw_name
    comrot_dir='/scratch1/NCEPDEV/stmp2/'+user_id+'/comrot/'+WORKFLOW_NAME
    if os.path.isdir(comrot_dir): delete_dir(comrot_dir)

    crow_path = CLONE_DIR+"/workflow/CROW"
    os.chdir(crow_path)
    
    subprocess.check_call(['bash','-c','./setup_case.sh -p HERA ../cases/3dvar.yaml '+WORKFLOW_NAME])
    subprocess.check_call(['bash','-c','./make_rocoto_xml_for.sh '+PROJECT_DIR+'/'+WORKFLOW_NAME])

    run_dir = PROJECT_DIR+'/'+WORKFLOW_NAME
    os.chdir(run_dir)

    #5. Runing the rocoto workflow and checking run status ---------------------
    max_runs   = 16*2
    count_runs = 0
    while (count_runs < max_runs):
        if os.path.exists("jobstat.log"): os.remove("jobstat.log")
        count_runs_=count_runs+1
        print('---------- rocotorun submit counts: %s ---------- '% count_runs_ )
        subprocess.check_call(['bash','-c','module load rocoto && rocotorun -w workflow.xml -d workflow.db'])
        subprocess.check_call(['bash','-c','module load rocoto && rocotostat -v 10 -w workflow.xml -d workflow.db > jobstat.log'])
        subprocess.call(["sed", "-i",  '/==============/d', "jobstat.log"])
        [alljobs_success, lapse_time]=check_job_status('jobstat.log')

        if alljobs_success: break
        time.sleep(lapse_time) # pause 3 or 6 minutes
        count_runs += 1

    #6. Checking the log file to validate run result----------------------------
    run_dir = PROJECT_DIR+'/'+WORKFLOW_NAME+'/log'
    for filename in find_files(run_dir, '*.log'):
        check_log(filename,'exit code 0:0')

