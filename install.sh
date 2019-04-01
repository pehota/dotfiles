#!/usr/bin/env bash

function checkOs {
  if [[ "$(uname)" == "$1" ]]; then
    echo true
  else
    echo false
  fi
}

IS_MAC=$(checkOs "Darwin")
IS_LINUX=$(checkOs "Linux")

if [[ "$IS_MAC" = false && "$IS_LINUX" = false ]]; then
  echo "Unsupported OS"
  exit 1
fi

if [[ "${BASH_VERSINFO:-0}" -le 3 ]]; then
  echo "Bash version is too old. Please upgrade to v4 or higher."
  exit 1
fi


. ./link.sh

# Install brew if necessary
if [[ "$IS_MAC" = true ]]; then
  . ./mac.sh
else
  . ./linux.sh
fi

. ./common.sh

echo "Done"

# # TODO: Add GIT completion
