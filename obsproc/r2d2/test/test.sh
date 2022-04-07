#!/bin/bash
set -eu
export R2D2_CONFIG=$PWD/r2d2_config.yaml
../bin/soca_store_obs.py --start 20150101 \
                         --end 20150102 \
                         --source ./obs-2-move \
                         --provider jcsda_soca \
                         --experiment benchmark_v2 \
                         --obstype adt \
                         --platforms c2 j2
