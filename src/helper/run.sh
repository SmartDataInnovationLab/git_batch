#!/bin/bash
set -e

# This script is run by the scheduler.


# ### pre run ### #

./.batch/check_symlinks.py .
./.batch/check_hash.py



# ### run ### #

echo "running notebooks..."
./.batch/exec_notebooks.py
echo "running notebooks... done"

# temp: create some dummy changes for the commit
echo "a" >> a.txt



# ### post run ### #

echo "todo: copy output to dir, hash it, make readonly and update symlinks"

./.batch/commit_changes.sh
