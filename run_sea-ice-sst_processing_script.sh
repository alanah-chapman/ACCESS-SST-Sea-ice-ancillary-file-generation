#!/bin/bash

#PBS -l ncpus=48

#PBS -l mem=192GB

#PBS -l walltime=01:00:00

#PBS -q express

#PBS -P q90

#PBS -l wd

#PBS -l storage=gdata/xp65+gdata/q90+scratch/q90+gdata/access

set -x
# cd to location of ancillary file generation scripts (python and karl taylor fortran scripts)
cd /g/data/q90/ac9768/ancil/make_ancils/SstSeaIce

# Clean environment
module purge

# load modules
module use /g/data/xp65/public/modules
module load gcc/14.2.0
module load intel-compiler/2021.10.0  

# compile fortran program
gfortran -g -fbacktrace /g/data/q90/ac9768/ancil/make_ancils/SstSeaIce/karl_taylor_hadgam3_n96e.f -o karl_taylor_n96

# Check if it compiled
if [[ ! -x ./karl_taylor_n96 ]]; then
    echo "Compilation failed"
    exit 1
fi

# load analysis3 environment
module load conda/analysis3
module use /g/data/access/ngm/modules
module load ants/1.1.0

# Run main Python script
python3 /g/data/q90/ac9768/ancil/make_ancils/SstSeaIce/run_make_amip_lbcs.py
