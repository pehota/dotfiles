#!/usr/bin/env bash
set -e

# Create a backup folder where all existing dotfiles will be saved to
mkdir -p ~/.dotfiles/.backup

declare -A commands_map=(
  ["xautolock"]="xautolock"
  ["dunst"]="dunst"
  ["picom"]="picom"
  ["i3lock"]="i3lock"
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
  pamac install $commands_to_install
fi

if [[ -d ~/.i3 ]]; then
  mv ~/.i3 ~/.dotfiles/.backup/ &> /dev/null
fi

if [ ! -L ~/.config/i3 ]; then
  mv ~/.config/i3 ~/.dotfiles/.backup/ &> /dev/null
  ln -s ~/.dotfiles/i3 ~/.config
fi

if [ ! -L ~/.config/picom ]; then
  mv ~/.config/picom ~/.dotfiles/.backup/ &> /dev/null
  ln -s ~/.dotfiles/picom ~/.config
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

# Fix apps windows rendering
{
  echo "export QT_AUTO_SCREEN_SCALE_FACTOR=0"
  echo "export \"QT_SCREEN_SCALE_FACTORS=1;1\""
} >> ~/.profile

. ./bluetooth.sh
