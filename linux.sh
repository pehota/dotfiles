#!/usr/bin/env bash

mkdir -p ~/.dotfiles/.backup

# Install the font for Powerline
if [ ! -f "$HOME/.local/share/fonts/Droid Sans Mono for Powerline Nerd Font Complete.otf" ]; then
  mkdir -p "$HOME/.local/share/fonts"
  cp "$HOME/.dotfiles/Droid Sans Mono for Powerline Nerd Font Complete.otf" ~/.local/share/fonts/
fi

declare -A commands_map=(
  ["git"]="git"
  ["curl"]="curl"
  ["rofi"]="rofi"
  ["kitty"]="kitty"
  ["tmux"]="tmux"
  ["exa"]="exa"
  ["preload"]="preload"
  ["python3"]="python3"
  ["nvim"]="neovim"
  ["rg"]="ripgrep"
  ["shellcheck"]="shellcheck"
  ["cmus"]="cmus"
  ["ranger"]="ranger"
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

# link rofi
[ ! -L ~/.config/rofi ] && {
  mv ~/.config/rofi ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/rofi ~/.config
}
