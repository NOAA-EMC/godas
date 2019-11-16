#!/bin/sh
set -xu

topdir=$(pwd)
echo $topdir

if [ $# -eq 1 ]; then
model=$1
fi
model=${model:-"godas"}

if [ $model = "godas" ]; then

#if on hera:  (should put on hpss eventually too)
ln -sf /scratch2/NCEPDEV/marineda/Jessica.Meixner/FIX/* $topdir/../fix/


fi
