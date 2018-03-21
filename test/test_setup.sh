#!/usr/bin/env bash
set -e
batch_base=$(mktemp -d)
./init_batch_repo.sh $batch_base

cd $(mktemp -d)
git init
git remote add batch $batch_base/repo.git


echo "-------------------"
echo "run tests with"
echo "./test/test.sh" $(realpath .) 
echo "-------------------"
