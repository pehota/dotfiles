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
  ["autorandr"]="autorandr" # conigure monitors
  ["bat"]="bat" # cat replacement
  ["cmus"]="cmus"
  ["curl"]="curl"
  ["exa"]="exa" # ls replacement
  ["fish"]="fish" # Friendly Interactive SHell
  ["git"]="git"
  ["kitty"]="kitty"
  ["nvim"]="neovim"
  ["playerctl"]="playerctl"
  ["preload"]="preload"
  ["python3"]="python3" # needed for neovim
  ["ranger"]="ranger" # file browser
  ["rg"]="ripgrep" # fast file search
  ["rofi"]="rofi" # dmenu
  ["shellcheck"]="shellcheck" # shell LSP
  ["tmux"]="tmux"
  ["unclutter"]="unclutter" # Hides the mouse cursor
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
 . ./setup-fish.sh

 . ./setup-ranger.sh
