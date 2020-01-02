1-1. two files in this test directory can be used to automatically set up GODAS system and run on HERA.

test.setup_godas.py

test.setup_godas.yaml

1-2. Set CLONE_DIR. For an example:

setenv CLONE_DIR /scratch2/NCEPDEV/marineda/user.id/godas.setup.name

1-2. Edit three variables in test.setup_godas.yaml. In test.setup_godas.py, GODAS system build and project set up options are specified through the yaml file. For an example of test.setup_godas.yaml:

PROJECT_DIR: /scratch2/NCEPDEV/marineda/Jong.Kim/scrub/sandbox

WORKFLOW_NAME: workflow_test

SKIP_BUILD: False

1-3. Run test.setup_godas.py: python test.setup_godas.py

1-4. If new GODAS system build is selected with 'SKIP_BUILD: False' in test.setup_godas.yaml, it will ask for your GitHub credentials.

1-5. During the run of test.setup_godas.py, rocoto workflow run command will be executed 32 times (max_runs = 16*2 at line number 155 in test.setup_godas.py) with rocoto job submitting intervals of 3 or 6 minutes. If user wants to change the number of rocoto runs, max_runs can be modified accordingly.

1-6. After loops of rocotorun/rocotostat runs, exit code values of PROJECT_DIR/WORKFLOW_NAME/log/*.log files will be checked for status of GODAS test runs. Upon completion of each job, "exit code 0:0" return value is used for confirmation of successful finish.