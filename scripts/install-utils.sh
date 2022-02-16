#!/usr/bin/env bash

SCRIPTS_FOLDER=$(dirname "$0")

source "$SCRIPTS_FOLDER/utils.sh"

# Install common packages
declare -A packages=(
  ["bat"]="bat" # Improved cat
  ["curl"]="curl"
  ["exa"]="exa" # Improved ls
  ["python3"]="python3" # needed for neovim
  ["rg"]="ripgrep" # fast file search
  ["appcleaner"]="appcleaner" # Uninstall apps not installed with brew
)
installPackages packages
