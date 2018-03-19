#!/usr/bin/env bash
set -e

if git remote get-url batch 2> /dev/null;
then
 batch_repo=$(git remote get-url batch)
 batch_base=$(realpath $batch_repo/..)
 if [ $? -eq 0 ]
 then
 echo ""
 else
  echo "something wrong with the path to the repo: $batch_base"
  exit 1
 fi

else
 echo "no batch-repo found"
 exit 1
fi

echo "removing dir: $batch_base"
echo "removing remote: batch"

rm -rf $batch_base
git remote remove batch
