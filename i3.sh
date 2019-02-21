#!/bin/bash
set -e

# Install polybar
if (! (which polybar > /dev/null)); then
  echo "Polybar neesds to be insalled"
fi

ln -s ~/.dotfiles/i3 ~/.config/i3
