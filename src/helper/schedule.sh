#!/bin/sh
set -e
# export LOG=$(mktemp)
export LOG=/tmp/mycondor_simulator.log
echo "view log with:  tail -f" $LOG
echo "./.batch/run.sh 2>>$LOG.err >>$LOG" | at now
