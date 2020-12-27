#!/usr/bin/env bash

PRINTER_PACKAGE="manjaro-printer"

if (! (command -v "$PRINTER_PACKAGE" &> /dev/null)); then
  pamac install "$PRINTER_PACKAGE" 
fi

# Add the current user to the sys group
sudo gpasswd -a $(whoami) sys

# Enable the printing service
sudo systemctl enable --now org.cups.cupsd.service

echo "Printer service enabled."
