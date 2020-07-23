#!/usr/bin/env bash

function checkOs {
  if [[ "$(uname)" == "$1" ]]; then
    echo true
  else
    echo false
  fi
}

function isPackageInstalled {
  test $(command -v "$1")
}

function installPackage {
  if (checkOs "Darwin"); then
    brew install "$1"
  else
    pamac install $1
  fi
}

function installPackages {
  local -n packages_ref=$1
  local packages_to_install=""

  for c in "${!packages_ref[@]}"
  do
    if (! (isPackageInstalled "$c")); then
      if [[ -n "$packages_to_install" ]]; then
        packages_to_install="$packages_to_install ${packages_ref[$c]}"
      else
        packages_to_install="${packages_ref[$c]}"
      fi
    fi
  done

  if [[ -n "$packages_to_install" ]]; then
    echo "Installing $packages_to_install ...\n"
    installPackage $packages_to_install
  fi
}
