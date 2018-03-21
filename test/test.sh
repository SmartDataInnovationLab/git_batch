#!/usr/bin/env bash

base=$(realpath $1)

cd $base

echo "a" >> a.txt
git add a.txt
git commit -m "."
git push batch master
sleep 5
git fetch --all
git reset --hard batch/master
