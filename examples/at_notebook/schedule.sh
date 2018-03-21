#!/bin/sh
set -e
export LOG=/tmp/at.log
echo "view log with:  tail -f" $LOG
echo "./run.sh >> $LOG 2>&1 " | at now
