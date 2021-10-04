#!/usr/bin/env bash

set -e

SCRIPTS_FOLDER=$(dirname "$0") 
PACKAGES_FOLDER="$(dirname $SCRIPTS_FOLDER)/dotfiles"

STOW_DIR="$PACKAGES_FOLDER"
STOW_TARGET="$HOME"

source "$SCRIPTS_FOLDER/utils.sh"

for package in $PACKAGES_FOLDER/*/; do
  package_name=$(basename $package)
  stow_dir="$STOW_DIR"
  stow_target="$STOW_TARGET"
  stow_package="$package_name"

  if [[ -f "$package/pre-install" || -f "$package/post-install" ]]; then
    stow_dir="$package"
    stow_package="content"
  fi

  if (! (isPackageInstalled $package_name)); then
    if [[ -f "$package/pre-install" ]]; then
      exec "$package/pre-install"
    fi

    echo "Installing $package_name ..."
    installPackage $package_name > /dev/null

    if [[ -f "$package/post-install" ]]; then
      exec "$package/post-install"
    fi
    echo "done"
  else
    echo "$package_name already installed"
  fi
  echo "stow -d "$stow_dir" -t "$stow_target" "$stow_package""
  stow -d "$stow_dir" -t "$stow_target" "$stow_package"
done
