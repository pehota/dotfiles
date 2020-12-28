#!/usr/bin/env bash
set -e

source ./utils.sh

echo "Patching mac keyboard ..."

if (! (isPackageInstalled dkms)); then
  echo "Installing dkms ..."
  installPackage dkms
fi

MODULE="hid-apple/1.0"

if [[ -n "$(sudo dkms status ${MODULE})" ]]; then
  echo "Keyboard patch is already applied"
  exit 0
fi

MOD_NAME=hid_apple
PATCH_REPO="https://github.com/free5lot/hid-apple-patched.git"
INSTALLATION_FOLDER=~/.tmp/$(basename $PATCH_REPO .git)

mkdir -p ~/.tmp
cd ~/.tmp

if [[ -d "$INSTALLATION_FOLDER" ]]; then
  rm -rf "$INSTALLATION_FOLDER"
fi

echo "Cloning patch ..."
git clone "$PATCH_REPO" 
cd $INSTALLATION_FOLDER

echo "Installing patch ..."
sudo dkms add .
sudo dkms build "$MODULE"
sudo dkms install "$MODULE"

echo "Updating related modprobe config ..."
{
  echo "options $MOD_NAME fnmode=1"
  echo "options $MOD_NAME swap_opt_cmd=1"
  echo "options $MOD_NAME rightalt_as_rightctrl=1"
} | sudo tee /etc/modprobe.d/hid_apple_pclayout.conf

echo "Adding patch module to kernel ..."
sudo modprobe -r $MOD_NAME; sudo modprobe $MOD_NAME

echo "Persisting changes ..."
for f in /etc/mkinitcpio.d/linux*.preset
  do
    sudo mkinitcpio -p "$(basename $f .preset)"
  done

echo "Done patching keyboard"
