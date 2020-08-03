#!/usr/bin/env bash

source ./utils.sh

IS_MAC=$(checkOs "Darwin")
IS_LINUX=$(checkOs "Linux")

if [[ "$IS_MAC" = false && "$IS_LINUX" = false ]]; then
  echo "Unsupported OS"
  exit 1
fi

if [[ -z "$BASH_VERSINFO" ]]; then
  echo "Please run the script in bash"
  exit 0
fi

if [[ "${BASH_VERSINFO:-0}" -le 3 ]]; then
  echo "Bash version is too old. Please upgrade to v4 or higher."
  exit 1
fi


. ./link.sh

if [[ "$IS_MAC" = true ]]; then
  . ./mac.sh
else
  . ./linux.sh
fi

. ./common.sh

if [[ "$DESKTOP_SESSION" = "i3" ]]; then
  . ./i3.sh
fi

echo "Done"
