#!/usr/bin/env bash

mkdir -p ~/.dotfiles/.backup

# Install the font for Powerline
if [ ! -f "$HOME/.local/share/fonts/Hack Regular Nerd Font Complete.ttf" ]; then
  mkdir -p "$HOME/.local/share/fonts"
  cp "$HOME/.dotfiles/Hack Regular Nerd Font Complete.ttf" ~/.local/share/fonts/
fi

# Make sure the current user has the correct groups
sudo gpasswd -a $(whoami) video

# Install pamac if needed
if [[ $(isPackageInstalled pamac) = false ]]; then
  echo "Installing pamac ..."
  sudo pacman -S pamac
fi

declare -A packages=(
  ["autorandr"]="autorandr" # conigure monitors
  ["bat"]="bat" # cat replacement
  ["cmus"]="cmus"
  ["curl"]="curl"
  ["exa"]="exa" # ls replacement
  ["fish"]="fish" # Friendly Interactive SHell
  ["git"]="git"
  ["kitty"]="kitty"
  ["nvim"]="neovim" # Vim Improved
  ["playerctl"]="playerctl"
  ["preload"]="preload"
  ["python3"]="python3" # needed for neovim
  ["ranger"]="ranger" # file browser
  ["rg"]="ripgrep" # fast file search
  ["rofi"]="rofi" # dmenu
  ["shellcheck"]="shellcheck" # shell LSP
  ["tmux"]="tmux"
  ["fnm"]="fnm-bin" # Fast Node Manager - nvm replacement
  ["unclutter"]="unclutter" # Hides the mouse cursor
)

installPackages packages

# link rofi
[ ! -L ~/.config/rofi ] && {
  mv ~/.config/rofi ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/rofi ~/.config
}

. ./add-swap-file.sh

# Support for external Apple keyboards
. ./linux_mac_kb.sh

. ./setup-shell.sh

. ./setup-ranger.sh
