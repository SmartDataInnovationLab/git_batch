#!/usr/bin/env bash

batch_base=$(realpath $1)
batch_repo="$batch_base/repo"
receive_hook=$(realpath .batch/post-receive)

########################################################################
############################# checks ###################################
########################################################################
set -e

if [ ! -f $receive_hook ]
then
 echo "Error: receive hooks does not exist. File note found: $receive_hook"
 exit 1
fi
if [ -d "$batch_base" ];
then
 echo "Error: the batch repo already exists. $batch_repo"
 exit 1
fi
if  ! git rev-parse --is-inside-work-tree
then
 echo "Error: the script must be executed in the worktree of the git-repo, that shall be connected on batch"
 exit 1
fi
if git remote|grep batch;
then
 echo "Error: this repos already has a batch-remote"
 exit 1
fi

########################################################################
############################ execute ###################################
########################################################################

echo "initializing batch base_dir at: $batch_base"
echo "initializing batch repo at: $batch_repo"

mkdir -p $batch_repo; cd $batch_repo && git init --bare; cd -
ln -s $receive_hook $batch_repo/hooks/post-receive
git remote add batch $batch_repo
