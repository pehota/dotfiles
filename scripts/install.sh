#!/usr/bin/env bash

SCRIPTS_FOLDER=$(dirname "$0")

source "$SCRIPTS_FOLDER/utils.sh"

if [[ ! checkOs ]]; then
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

installPackageManager

exec "$SCRIPTS_FOLDER/install-packages.sh"

echo "Done"
