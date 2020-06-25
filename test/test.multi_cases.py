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
    lapse_min = 60
    lapse_time= lapse_min * 3

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
            lapse_time = lapse_min * 6
            print(
                jobcycle[index],
                jobtask[index],
                jobstate[index],
                jobtries[index])
        if jobstate[index] == 'QUEUED':
            count_qued = 1
            lapse_time = lapse_min * 6
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
    with open('test.multi_cases.yaml') as input_file:
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
    GODAS_BRANCH_NAME = input.get('GODAS_BRANCH_NAME')
    SOCA_BRANCH_NAME = input.get('SOCA_BRANCH_NAME')
    SOCA_CONFIG_BRANCH_NAME = input.get('SOCA_CONFIG_BRANCH_NAME')
    BUILD_COMPILER = input.get('BUILD_COMPILER')
    MACHINE_ID = input.get('MACHINE_ID')
    TEST_CASE = input.get('TEST_CASE')
    USER = os.getenv('USER')
    os.environ["CLONE_DIR"] = CLONE_DIR
    os.environ['MACHINE_ID'] = MACHINE_ID
    path = os.getcwd()

    print ('USER: '+USER)
    print ('WORKFLOW NAMES: ',WORKFLOW_NAME)
    print ('TEST CASES: ',TEST_CASE)
    print ("----- Current work directory is %s" % path)

    if not SKIP_BUILD:

        # 1. Switch GODAS/soca-config branches at CLONE_DIR --------
        print('-----------Setup GODAS system at:', CLONE_DIR)
        os.chdir(CLONE_DIR)
        if GODAS_BRANCH_NAME.strip() != 'develop':
            os.system("git checkout " + GODAS_BRANCH_NAME)

        soca_config_path = CLONE_DIR + '/src/soca-bundle/soca-config'
        os.chdir(soca_config_path)
        os.system('git checkout '+SOCA_CONFIG_BRANCH_NAME.strip())

    # 2. Preparing the workflow and rocoto run case ------------------------                             
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

    subprocess.call(
        ["sed", "-i", r'/FIX_SCRUB:/c\  FIX_SCRUB: True', "user.yaml"])

    crow_path = CLONE_DIR + "/workflow/CROW"
    os.chdir(crow_path)

    n_cases = len(WORKFLOW_NAME)
    i = 0
    while (i < n_cases):
        if MACHINE_ID.strip() in 'orion':
            subprocess.check_call(
                ['sh','-c','./setup_case.sh -p ' + MACHINE_ID.upper() + ' ../cases/' + TEST_CASE[i].strip() + ' ' + WORKFLOW_NAME[i]])
            subprocess.check_call(
                ['sh','-c','./make_rocoto_xml_for.sh ' + EXPROOT + '/' + WORKFLOW_NAME[i]])
        else:
            subprocess.check_call(
                ['bash', '-c', './setup_case.sh -p ' + MACHINE_ID.upper() + ' ../cases/'+ TEST_CASE[i].strip() + ' ' + WORKFLOW_NAME[i]])
            subprocess.check_call(
                ['bash', '-c', './make_rocoto_xml_for.sh ' + EXPROOT + '/' + WORKFLOW_NAME[i]])
            i += 1

    # 6. Runing the rocoto workflow and checking run status ------------------                                             
    n_cases = len(WORKFLOW_NAME)
    i = 0
    while (i < n_cases):

        run_dir = EXPROOT + '/' + WORKFLOW_NAME[i]
        os.chdir(run_dir)

        max_runs = 10 * 2
        count_runs = 0
        while (count_runs < max_runs):
            if os.path.exists("jobstat.log"):
                os.remove("jobstat.log")
            count_runs_ = count_runs + 1
            print('Workflowname=',WORKFLOW_NAME[i],'  --- rocotorun submit counts: %s --- ' %count_runs_)

            if MACHINE_ID.strip() in 'orion':
                subprocess.check_call(
                    ['sh', '-c', 'module load contrib && module load rocoto/1.3.1 && rocotorun -w workflow.xml -d workflow.db'])
                subprocess.check_call(
                    ['sh', '-c', 'module load contrib && module load rocoto/1.3.1 && rocotostat -v 10 -w workflow.xml -d workflow.d\
                    b > jobstat.log'])
            else:
                subprocess.check_call(
                    ['bash', '-c', 'module load rocoto && rocotorun -w workflow.xml -d workflow.db'])
                subprocess.check_call(
                    ['bash', '-c', 'module load rocoto && rocotostat -v 10 -w workflow.xml -d workflow.db > jobstat.log'])
            subprocess.call(["sed", "-i", '/==============/d', "jobstat.log"])
            [alljobs_success, lapse_time] = check_job_status('jobstat.log')


            if alljobs_success:
                break
            time.sleep(lapse_time)  # pause 3 or 6 minutes
            count_runs +=1
        i += 1
