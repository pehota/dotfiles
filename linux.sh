#!/usr/bin/env bash

mkdir -p ~/.dotfiles/.backup

# Install the font for Powerline
if [ ! -f "$HOME/.local/share/fonts/Hack Regular Nerd Font Complete.ttf" ]; then
  mkdir -p "$HOME/.local/share/fonts"
  cp "$HOME/.dotfiles/Hack Regular Nerd Font Complete.ttf" ~/.local/share/fonts/
fi

# Install pamac if needed
if(! (command -v pamac &> /dev/null)); then
  echo "Installing pamac ..."
  sudo pacman -S pamac
fi

declare -A commands_map=(
  ["git"]="git"
  ["curl"]="curl"
  ["fish"]="fish"
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
  ["playerctl"]="playerctl"
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
  pamac install --no-confirm $commands_to_install
fi

# link rofi
[ ! -L ~/.config/rofi ] && {
  mv ~/.config/rofi ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/rofi ~/.config
}
