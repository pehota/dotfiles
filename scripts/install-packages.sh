#!/usr/bin/env bash

set -e

SCRIPTS_FOLDER=$(dirname "$0") 
PACKAGES_FOLDER="$(dirname $SCRIPTS_FOLDER)/dotfiles"

STOW_DIR="$PACKAGES_FOLDER"
STOW_TARGET="$(dirname $SCRIPTS_FOLDER)/test-stow" # $HOME

source "$SCRIPTS_FOLDER/utils.sh"

for package in $PACKAGES_FOLDER/*/; do
  package_name=$(basename $package)
  stow_dir="$STOW_DIR"
  stow_target="$STOW_TARGET"

  if (! (isPackageInstalled $package_name)); then
    if [[ -f "$package/pre-install" ]]; then
      exec "$package/pre-install"
      stow_dir="$package"
      package_name="content"
    fi

    echo "Installing $package_name ..."
    installPackage $package_name > /dev/null

    if [[ -f "$package/post-install" ]]; then
      exec "$package/post-install"
      stow_dir="$package"
      package_name="content"
    fi
    echo "done"
  else
    echo "$package_name already installed"
  fi
  stow -d "$stow_dir" -t "$stow_target" "$package_name"
done
