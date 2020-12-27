#!/usr/bin/env bash

source ./utils.sh

# Install the font for Powerline
if [ ! -f "$HOME/.local/share/fonts/Hack Regular Nerd Font Complete.ttf" ]; then
  mkdir -p "$HOME/.local/share/fonts"
  cp "$HOME/.dotfiles/Hack Regular Nerd Font Complete.ttf" ~/.local/share/fonts/
fi

installPackage "otf-nerd-fonts-fira-code"

# Make sure the current user has the correct groups
sudo gpasswd -a $(whoami) video

# Install pamac if needed
if [[ $(isPackageInstalled pamac) = false ]]; then
  echo "Installing pamac ..."
  sudo pacman -S pamac
fi

declare -A packages=(
  ["autorandr"]="autorandr" # conigure monitors
  ["fnm"]="fnm-bin" # Fast Node Manager - nvm replacement
  ["playerctl"]="playerctl"
  ["preload"]="preload"
  ["ranger"]="ranger" # file browser
  ["rofi"]="rofi" # dmenu replacement
  ["unclutter"]="unclutter" # Hides the mouse cursor
  ["refind-install"]="refind" # Boot manager
)
installPackages packages

# link rofi
createSimlink rofi ~/.config

 . ./setup-shell.sh

. ./add-swap-file.sh

# Support for external Apple keyboards
. ./linux_mac_kb.sh

. ./setup-shell.sh

. ./setup-ranger.sh
