#!/bin/bash
set -e

# Create a backup folder where all existing dotfiles will be saved to
mkdir -p ~/.dotfiles/.backup

declare -A commands_map=(
  ["xautolock"]="xautolock"
  ["dunst"]="dunst"
  ["compton"]="compton"
  ["i3status-rs"]="i3status-rust-git"
  ["light"]="light"
  ["redshift"]="redshift"
  ["scrot"]="scrot"
  ["xclip"]="xclip"
  ["xkblayout-state"]="xkblayout-state-git"
  ["feh"]="feh"
)

commands_to_install=""

for c in "${!commands_map[@]}"
do
  if (! (command -v "$c" &> /dev/null)); then
    if [[ -n "$commands_to_install" ]]; then
      commands_to_install="$commands_to_install ${commands_map[$c]}"
    else
      commands_to_install="${commands_map[$c]}"
    fi
  fi
done

if [[ -n "$commands_to_install" ]]; then
  echo "Installing $commands_to_install"
  yes | sudo pacman -Sy $commands_to_install
fi

if [ ! -L ~/.config/i3 ]; then
  mv ~/.config/i3 ~/.dotfiles/.backup/ &> /dev/null
  ln -s ~/.dotfiles/i3 ~/.config
fi

if [ ! -L ~/.config/compton ]; then
  mv ~/.config/compton ~/.dotfiles/.backup/ &> /dev/null
  ln -s ~/.dotfiles/compton ~/.config
fi

if [ ! -L ~/.config/dunst ]; then
  mv ~/.config/dunst ~/.dotfiles/.backup/ &> /dev/null
  ln -s ~/.dotfiles/dunst ~/.config
fi

if [[ -z "$TERMINAL" ]]; then
  echo "Adding \$TERMINAL environment variable which requires \`sudo\`"
  {
    echo "export TERMINAL=kitty" | sudo tee -a /etc/environment
  } >> /dev/null
fi

{
  echo "if [ \"\$DESKTOP_SESSION\" = \"i3\" ]; then"
  echo "  export \"\$(gnome-keyring-daemon --start --components=secrets,ssh)\""
  echo "fi"
  echo ""
} >> ~/.bash_profile

# Fix apps windows rendering
{
  echo "export QT_AUTO_SCREEN_SCALE_FACTOR=0"
  echo "export \"QT_SCREEN_SCALE_FACTORS=1;1\""
} >> ~/.profile

. ./bluetooth.sh
