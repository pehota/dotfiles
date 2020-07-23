#!/usr/bin/env bash

PRINTER_PACKAGE="manjaro-printer"

if (! (isPackageInstalled $PRINTER_PACKAGE)); then
  installPackage $PRINTER_PACKAGE
fi

# Add the current user to the sys group
sudo gpasswd -a $(whoami) sys

# Enable the printing service
sudo systemctl enable --now org.cups.cupsd.service

echo "Printer service enabled."
