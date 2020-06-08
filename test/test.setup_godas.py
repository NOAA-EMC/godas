#!/usr/bin/env python3

import sys
import os
import fnmatch
import os.path
import argparse
import yaml
import io
import shutil
import shlex
import subprocess
import time
import pathlib

def make_dir(path):
    if os.path.isdir(path):
        delete_dir(path)
    try:
        os.makedirs(path)
    except OSError:
        print("----- Creation of the directory %s failed" % path)
    else:
        print("----- Successfully created the directory %s " % path)

def delete_dir(path):
    try:
        shutil.rmtree(path)
    except OSError:
        print("----- Deletion of the directory %s failed" % path)
    else:
        print("----- Successfully deleted the directory %s" % path)

def check_log(filename, string):
    if os.path.exists(filename):
        print("----- Checking log file:", filename)
        with open(filename) as myfile:
            if string in myfile.read():
                print("---------- Test successfully ran ----------")
            else:
                print("---------- Test run failed ----------------")
    else:
        print("----- log file not available to check:", filename)

def check_job_status(filename):
    jobcycle = []  # col 0
    jobtask = []   # col 1
    jobstate = []  # col 3
    jobtries = []  # col 5
    with open(filename) as inf:
        for line in inf:
            parts = line.split()  # split line into parts
            if len(parts) > 1:   # if at least 2 parts/columns
                jobcycle.append(parts[0])
                jobtask.append(parts[1])
                jobstate.append(parts[3])
                jobtries.append(parts[5])

    alljobs_success = False
    count_success = 0
    count_submit = 0
    count_qued = 0
    lapse_time = 60. * 3

    for index in range(len(jobtask)):
        if jobstate[index] == 'SUCCEEDED':
            count_success += 1
            print(
                jobcycle[index],
                jobtask[index],
                jobstate[index],
                jobtries[index])
        if jobstate[index] == 'SUBMITTING':
            count_submit = 1
            lapse_time = 60. * 6
            print(
                jobcycle[index],
                jobtask[index],
                jobstate[index],
                jobtries[index])
        if jobstate[index] == 'QUEUED':
            count_qued = 1
            lapse_time = 60. * 6
            print(
                jobcycle[index],
                jobtask[index],
                jobstate[index],
                jobtries[index])
        if count_success == len(jobtask):
            alljobs_success = True

    return alljobs_success, lapse_time

if __name__ == '__main__':
    # 1. Read directory paths, build/ctest option, and workflow name ---------
    with open('test.setup_godas.yaml') as input_file:
        input = yaml.load(input_file)

    if 'CLONE_DIR' is os.environ:
        CLONE_DIR = os.environ.get('CLONE_DIR')
        print('The CLONE_DIR is set as system variable')
    else:
        CLONE_DIR = input.get('CLONE_DIR')

    EXPROOT = input.get('EXPROOT')
    COMROOT = input.get('COMROOT')
    DATAROOT = input.get('DATAROOT')
    WORKFLOW_NAME = input.get('WORKFLOW_NAME')
    SKIP_BUILD = input.get('SKIP_BUILD')
    BRANCH_NAME = input.get('BRANCH_NAME')
    BUILD_COMPILER = input.get('BUILD_COMPILER')
    MACHINE_ID = input.get('MACHINE_ID')
    USER = os.getenv('USER')
    os.environ["CLONE_DIR"] = CLONE_DIR
    os.environ['MACHINE_ID'] = MACHINE_ID
    path = os.getcwd()

    print ('USER:'+USER)
    print ('WORKFLOW_NAME'+WORKFLOW_NAME)
    print ("----- Current work directory is %s" % path)

    if not SKIP_BUILD:
        if os.path.isdir(CLONE_DIR):
            delete_dir(CLONE_DIR)

        # 1. Setup GODAS system at CLONE_DIR ----------------------------------
        print('-----------Setup GODAS system at:', CLONE_DIR)
        return_value = 0
        return_value = os.system(
            "git clone https://github.com/NOAA-EMC/godas.git " + CLONE_DIR)
        if (return_value != 0):
            sys.exit('-----------Trouble to clone GODAS repo -----------')
        os.chdir(CLONE_DIR)
        if BRANCH_NAME.strip() is not 'develop':
            os.system("git checkout " + BRANCH_NAME)
        os.system("git submodule update --init --recursive")

        os.chdir(CLONE_DIR + "/src")
        os.system("sh checkout.sh godas")
        os.system("sh link.sh godas " + MACHINE_ID)
        os.system("sh build_DATM-MOM6-CICE5.sh")

        # 2. Clone and build soca system inside CLONE_DIR----------------------
        print('-----------Clone and build SOCA system at:', CLONE_DIR)
        return_value = 0
        if os.path.isdir(CLONE_DIR + "/src/soca-bundle"):
            delete_dir(CLONE_DIR + "/src/soca-bundle")
        return_value = os.system(
            "git clone --branch release/stable-nightly https://github.com/JCSDA/soca-bundle.git " +
            CLONE_DIR +
            "/src/soca-bundle")
        if (return_value != 0):
            sys.exit('-----------Trouble to clone SOCA Bundle -----------')
        
        build_dir = CLONE_DIR + '/build'
        make_dir(build_dir)
        os.chdir(build_dir)

        if MACHINE_ID.strip() in 'hera':
            try:
                subprocess.check_call(
                    ['csh',
                     '-c',
                     'module purge; source ../modulefiles/' +
                      MACHINE_ID + '.' + BUILD_COMPILER +
                     '; source ../modulefiles/' + MACHINE_ID +
                     '.setenv module list; ecbuild --build=release -DMPIEXEC=$MPIEXEC -DMPIEXEC_EXECUTABLE=$MPIEXEC -DBUILD_ECKIT=YES -DBUILD_CRTM=OFF ../src/soca-bundle; make -j12'])
            except subprocess.CalledProcessError as error:
                sys.exit(
                    '-----------Trouble to build SOCA with ' + 
                    BUILD_COMPILER + 'at' + MACHINE_ID + '-----------')
        elif MACHINE_ID.strip() in 'orion':
            try:
                subprocess.check_call(
                    ['sh',
                     '-c',
                     'module purge; source ../modulefiles/' +
                      MACHINE_ID + '.' + BUILD_COMPILER +
                     '; source ../modulefiles/' + MACHINE_ID +
                     '.setenv module list; ecbuild -DBUILD_ECKIT=ON -DBUILD_METIS=ON -DBUILD_CRTM=ON ../ecbuild -DBUILD_ECKIT=ON -DBUILD_METIS=ON -DBUILD_CRTM=ON ../src/soca-bundle; make -j12'])
            except subprocess.CalledProcessError as error:
                sys.exit(
                    '-----------Trouble to build SOCA with ' + 
                    BUILD_COMPILER + 'at' + MACHINE_ID + '-----------')
        else:
            sys.exit('-----------No rule to build SOCA at '+ MACHINE_ID + '-----------') 
        soca_config_path = CLONE_DIR + '/src/soca-bundle/soca-config'
        os.chdir(soca_config_path)
        os.system('git checkout develop')

        # 3. Clone and build the UMD-LETKF ------------------------------------
        os.chdir(CLONE_DIR)
        if os.path.isdir(CLONE_DIR + "/src/letkf"):
            delete_dir(CLONE_DIR + "/src/letkf")
        print('-----------Clone and build the UMD-LETKF at:', CLONE_DIR)
        return_value = 0
        return_value = os.system(
            "git clone --recursive https://github.com/NOAA-EMC/UMD-LETKF.git ./src/letkf")
        if (return_value != 0):
            sys.exit('-----------Trouble to clone UMD-LETKF repo -----------')
        try:
            os.system("sh " + CLONE_DIR + "/src/letkf_build.sh")
        except subprocess.CalledProcessError as error:
            sys.exit('-----------Trouble to build LETKF -----------')

        # 4. Preparing the mom6tools
        src_fl = CLONE_DIR + '/src/mom6-tools.plot/*.py '
        des_fl = CLONE_DIR + '/build/bin/ '
        os.system('cp ' + src_fl + des_fl)

    # 5. Preparing the workflow and rocoto run case --------------------------
    os.chdir(CLONE_DIR + "/workflow")
    shutil.copyfile('user.yaml.default', 'user.yaml')
    subprocess.call(
        ["sed", "-i", r'/EXPROOT/c\  EXPROOT: ' + EXPROOT, "user.yaml"])
    subprocess.call(
        ["sed", "-i", r'/COMROOT/c\  COMROOT: ' + COMROOT, "user.yaml"])
    subprocess.call(
        ["sed", "-i", r'/DATAROOT/c\  DATAROOT: ' + DATAROOT, "user.yaml"])
    subprocess.call(
        ["sed", "-i", r'/cpu_project/c\  cpu_project: marine-cpu', "user.yaml"])
    subprocess.call(
        ["sed", "-i", r'/hpss_project/c\  hpss_project: emc-marine', "user.yaml"])

    if os.path.isdir(EXPROOT):
        delete_dir(EXPROOT)
    make_dir(EXPROOT)
    comrot_dir = '/scratch1/NCEPDEV/stmp2/' + USER + '/comrot/' + WORKFLOW_NAME

    subprocess.call(
        ["sed", "-i", r'/FIX_SCRUB:/c\  FIX_SCRUB: True', "user.yaml"])

    if os.path.isdir(comrot_dir):
        delete_dir(comrot_dir)

    crow_path = CLONE_DIR + "/workflow/CROW"
    os.chdir(crow_path)
    
    subprocess.check_call(
                ['bash', '-c', './setup_case.sh -p ' + MACHINE_ID.upper() + ' ../cases/3dvar.yaml ' + WORKFLOW_NAME])
    subprocess.check_call(
        ['bash', '-c', './make_rocoto_xml_for.sh ' + EXPROOT + '/' + WORKFLOW_NAME])

    run_dir = EXPROOT + '/' + WORKFLOW_NAME
    os.chdir(run_dir)

    # 6. Runing the rocoto workflow and checking run status ------------------
    max_runs = 16 * 2
    count_runs = 0
    while (count_runs < max_runs):
        if os.path.exists("jobstat.log"):
            os.remove("jobstat.log")
        count_runs_ = count_runs + 1
        print(
            '---------- rocotorun submit counts: %s ---------- ' %
            count_runs_)
        subprocess.check_call(
            ['bash', '-c', 'module load rocoto && rocotorun -w workflow.xml -d workflow.db'])
        subprocess.check_call(
            ['bash', '-c', 'module load rocoto && rocotostat -v 10 -w workflow.xml -d workflow.db > jobstat.log'])
        subprocess.call(["sed", "-i", '/==============/d', "jobstat.log"])
        [alljobs_success, lapse_time] = check_job_status('jobstat.log')

        if alljobs_success:
            break
        time.sleep(lapse_time)  # pause 3 or 6 minutes
        count_runs += 1

    # 7. Checking the log file to validate run result-------------------------
    run_dir = EXPROOT + '/' + WORKFLOW_NAME + '/log'
    for filename in pathlib.Path('run_dir').glob('*.log'):
        check_log(filename, 'exit code 0:0')
