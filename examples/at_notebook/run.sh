#!/bin/bash
set -e
# This script is run by the scheduler.
./exec_notebook.py

# git behave a little differently when run via at on a worktree, that's why we have to do some things explicitly
GIT=$(which git)
unset GIT_DIR
${GIT} add --all .
${GIT} commit -m "done!"
