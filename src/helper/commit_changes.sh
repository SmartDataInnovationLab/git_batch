#!/usr/bin/env bash

GIT=$(which git)
unset GIT_DIR

${GIT} add --all .
${GIT} commit -m "done!"
