#!/bin/bash

export GIN_MODE=release

if [ "$(id -un)" != aptly ]; then
  echo "Executing aptly command via sudo"
  exec sudo -u aptly /usr/bin/aptly "$@"
else
  exec /usr/bin/aptly "$@"
fi
