#!/usr/bin/env bash
# set -e

source ./utils.sh

# Create a backup folder where all existing dotfiles will be saved to
mkdir -p ~/.dotfiles/.backup

declare -A packages=(
  ["xautolock"]="xautolock"
  ["dunst"]="dunst"
  ["picom"]="picom"
  ["i3lock"]="i3lock"
  ["i3status-rs"]="i3status-rust-git"
  ["kbdd"]="kbdd-git"
  ["light"]="light"
  ["redshift"]="redshift"
  ["escrotum"]="escrotum-git"
  ["xclip"]="xclip"
  ["xkblayout-state"]="xkblayout-state-git"
  ["feh"]="feh"
)

installPackages packages

# Sound driver and firmware
installPackage sof-firmware
installPackage alsa-ucm-conf
installPackage pulseaudio
installPackage pulseaudio-alsa

# Fonts
installPackage ttf-font-awesome
installPackage ttf-font-awesome-4
installPackage ttf-windows
installPackage ttf-apple-emoji

if [[ -d ~/.i3 ]]; then
  mv ~/.i3 ~/.dotfiles/.backup/ &> /dev/null
fi

createSimlink i3 ~/.config
createSimlink picom ~/.config
createSimlink dunst ~/.config
createSimlink xprofile

if [[ -z "$TERMINAL" ]]; then
  echo "Adding \$TERMINAL environment variable which requires \`sudo\`"
  {
    echo "export TERMINAL=kitty" | sudo tee -a /etc/environment
  } >> /dev/null
fi

# Fix applications windows rendering
{
  echo "export QT_AUTO_SCREEN_SCALE_FACTOR=0"
  echo "export \"QT_SCREEN_SCALE_FACTORS=1;1\""
} >> ~/.profile

. ./bluetooth.sh

. ./setup-printing.sh
