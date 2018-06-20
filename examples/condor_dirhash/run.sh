#!/bin/bash
set -e

# $workdir is set in run.sub
echo "workdir: " $workdir
cd $workdir

# setup_anaconda
. /etc/profile.d/anaconda.sh
setup-anaconda
source activate anaconda-py35

echo "Starting job ..."
./exec_notebook.py
