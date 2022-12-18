#!/bin/bash
set -eo pipefail
shopt -s nullglob
BASE=${PWD}

if [ "${1}" = 'yarn' ]; then
  echo "Installing yarn libraries..."
  cd ${BASE} && yarn install --frozen-lockfile
fi

exec "$@"
