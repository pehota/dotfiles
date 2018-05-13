#!/bin/bash
set -e

if (! (which i3blocks > /dev/null)); then
  echo "Installing i3blocks ..."
  sudo apt install i3blocks
fi

ln -s ~/.dotfiles/i3 ~/.config/i3
ln -s ~/.dotfiles/i3/i3blocks.conf ~/.i3blocks.conf

