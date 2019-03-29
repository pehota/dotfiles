#!/usr/bin/env bash

mkdir -p ~/.dotfiles_bkp

# Install the font for Powerline
if [ ! -f "$HOME/.local/share/fonts/Droid Sans Mono for Powerline Nerd Font Complete.otf" ]; then
  mkdir -p "$HOME/.local/share/fonts"
  cp "$HOME/.dotfiles/Droid Sans Mono for Powerline Nerd Font Complete.otf" ~/.local/share/fonts/
fi


# Configure git to use the credentials from the keyring
# Install the keyring if necessary
# if (! (command -v libgnome-keyring-dev > /dev/null) ); then
  # sudo pacman -S libgnome-keyring-dev
  # sudo make --directory=/usr/share/doc/git/contrib/credential/gnome-keyring
# fi
# git config --global credential.helper /usr/share/doc/git/contrib/credential/gnome-keyring/git-credential-gnome-keyring

declare -A commands_map=(
  ["git"]="git"
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

# Install Neovim
if (! (command -v nvim > /dev/null)); then
  commands_to_install="$commands_to_install neovim"
fi

if [[ -n "$commands_to_install" ]]; then
  echo "Installing $commands_to_install"
  yes | sudo pacman -Sy $commands_to_install
fi

# link rofi
[ ! -L ~/.config/rofi ] && {
  mv ~/.config/rofi ~/.dotfiles_bkp/ &> /dev/null
  ln -sf ~/.dotfiles/rofi ~/.config
}
