#!/usr/bin/env bash

base=$(realpath $1)

cd $base
cd repo
echo "a" >> a.txt
git commit -am "."
git push batch
sleep 5
git fetch --all
git reset --hard origin/master
