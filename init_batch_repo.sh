#!/usr/bin/env bash
set -e

echo $1
batch_base=$(realpath $1)
batch_repo="$batch_base/repo.git"

########################################################################
############################# checks ###################################
########################################################################
if [ -d "$batch_base" ];
then
  if ! [ -z "$(ls -A $batch_base)" ]; then
   echo "Error: directory exists and is not empty: $batch_base"
   exit 1
  fi
fi

########################################################################
############################ execute ###################################
########################################################################

echo "initializing batch base_dir at: $batch_base"
echo "initializing batch repo at: $batch_repo"

mkdir -p $batch_repo; cd $batch_repo
git init --bare
cat > $batch_repo/hooks/post-receive <<-EOM
#! /bin/sh
set -e
echo "DEBUG: post-receive invoked"
echo "ref $ref received.  Starting batch-job..."
worktree_base=$(realpath ..)
branch=$(date +%FT%H%M%S)
worktree=$worktree_base/$branch
git worktree add $worktree

cd $worktree
./schedule.sh

echo "when the job is done, fetch results with: git pull batch" $branch
EOM

echo "repo successfully created. Now you can set it as remote by executing: "
echo "git remote add batch $batch_repo"
echo ""
echo "or if it is located on a remote machine: "
echo "git remote add batch ssh://user@host$batch_repo"
