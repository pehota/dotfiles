#!/usr/bin/env bash

set -e

function checkOs {
  if [[ "$(uname)" == "$1" ]]; then
    echo true
  else
    echo false
  fi
}

IS_MAC=$(checkOs "Darwin")
IS_LINUX=$(checkOs "Linux")

echo "IS_MAC=$IS_MAC"
echo "IS_LINUX=$IS_LINUX"
exit 1

./link.sh

# Install brew if necessary
if [[ $IS_MAC ]]; then
  ./mac.sh
else
  ./linux.sh
fi

./common.sh

echo "Done"

# # TODO: Add GIT completion
