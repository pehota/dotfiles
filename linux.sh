#!/usr/bin/env bash

source ./utils.sh

# Make sure the current user has the correct groups
sudo gpasswd -a $(whoami) video

# Install pamac if needed
if [[ $(isPackageInstalled pamac) = false ]]; then
  echo "Installing pamac ..."
  sudo pacman -S pamac
fi

installPackage "otf-nerd-fonts-fira-code"

declare -A packages=(
  ["autorandr"]="autorandr" # conigure monitors
  ["fnm"]="fnm-bin" # Fast Node Manager - nvm replacement
  ["playerctl"]="playerctl"
  ["preload"]="preload"
  ["ranger"]="ranger" # file browser
  ["rofi"]="rofi" # dmenu replacement
  ["unclutter"]="unclutter" # Hides the mouse cursor
  ["refind-install"]="refind" # Boot manager
  ["bash-language-server"]="bash-language-server"
  ["direnv"]="direnv-bin"
  ["zoxide"]="zoxide-bin"
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
