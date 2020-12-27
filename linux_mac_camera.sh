#!/usr/bin/env bash

CAMERA_DRIVER="bcwc-pcie-git"

if (! (isPackageInstalled $CAMERA_DRIVER)); then
  installPackage $CAMERA_DRIVER
fi

# Make sure the current user has the correct groups
sudo gpasswd -a $(whoami) video
