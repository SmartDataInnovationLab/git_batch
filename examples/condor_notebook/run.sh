#!/bin/bash
set -e

# $workdir is set in run.sub
echo "workdir: " $workdir
cd $workdir

# setup_anaconda
. /etc/profile.d/anaconda.sh
setup-anaconda
source activate anaconda510-py35-with-jupyter_cms

echo "Starting job ..."
./exec_notebook.py

# git behave a little differently when run via at on a worktree, that's why we have to do some things explicitly
GIT=$(which git)
unset GIT_DIR
${GIT} add --all .
${GIT} commit -m "done!"

# turn this branch into master for convinient pull later
branch=$(${GIT} rev-parse --abbrev-ref HEAD)
${GIT} checkout master
${GIT} reset --hard $branch

#alternative: git branch -M $branch master
