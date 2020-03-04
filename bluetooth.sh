#!/usr/bin/env bash

if [[ "enabled" != $(systemctl is-enabled bluetooth) ]]; then
  echo "Enabling bluetooth service ..."
  sudo systemctl enable bluetooth
  sudo systemctl start bluetooth
fi

pulse_config="/etc/pulse/default.pa"
if [[ -f $pulse_config ]]; then
  echo "Updating auto connect for bluetooth"
  echo "# automatically switch to newly-connected devices" | sudo tee -a $pulse_config > /dev/null
  echo "load-module module-switch-on-connect" | sudo tee -a $pulse_config > /dev/null
else
  echo "Cannot update auto-connect for bluetooth. ($pulse_config) is missing."
fi

echo "AutoEnable=true" | sudo tee -a /etc/bluetooth/main.conf > /dev/null

echo "Installing bluetooth utilities ..."
pamac install --no-confirm pulseaudio-bluetooth blueman
