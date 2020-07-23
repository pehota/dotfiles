#!/usr/bin/env bash

CAMERA_DRIVER="bcwc-pcie-git"

if (! (isPackageInstalled $CAMERA_DRIVER)); then
  installPackage $CAMERA_DRIVER
fi
