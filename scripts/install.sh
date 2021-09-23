#!/usr/bin/env bash

source ./utils.sh

if [[ "$IS_MAC" == "0" && "$IS_LINUX" == "0" ]]; then
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

exec ./install-packages.sh

if [[ "$DESKTOP_SESSION" == "i3" ]]; then
  . ./i3.sh
fi

echo "Done"
