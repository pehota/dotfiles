#!/usr/bin/env bash
echo "Patching mac keyboard ..."

if (! (command -v dkms &> /dev/null)); then
  echo "Installing dkms ..."
  sudo pamac -S dkms
fi

if [[ -n "$(sudo dkms status hid-apple-patched)" ]]; then
  echo "Keyboard patch is already applied"
  exit 0
fi

mkdir -p ~/.tmp
cd ~/.tmp

PATCH_REPO="https://github.com/free5lot/hid-apple-patched.git"

echo "Cloning patch ..."
git clone "$PATCH_REPO" 2> /dev/null
cd "$(basename $PATCH_REPO .git)"

"Installing patch ..."
sudo dkms add . 2> /dev/null
sudo dkms build hid-apple/1.0
sudo dkms install hid-apple/1.0

MOD_NAME=hid_apple

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
