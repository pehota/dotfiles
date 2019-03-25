#!/usr/bin/env bash

mkdir -p ~/.dotfiles_bkp

# Install the font for Powerline
if [ ! -f "$HOME/.local/share/fonts/Droid Sans Mono for Powerline Nerd Font Complete.otf" ]; then
	cp "$HOME/.dotfiles/Droid Sans Mono for Powerline Nerd Font Complete.otf" ~/.local/share/fonts/
fi


# Configure git to use the credentials from the keyring
# Install the keyring if necessary
# if (! (command -v libgnome-keyring-dev > /dev/null) ); then
  # sudo pacman -S libgnome-keyring-dev
  # sudo make --directory=/usr/share/doc/git/contrib/credential/gnome-keyring
# fi
# git config --global credential.helper /usr/share/doc/git/contrib/credential/gnome-keyring/git-credential-gnome-keyring

commands=(
  git
  rofi
  alacritty
	tmux
	exa
	nvm
	rg
  preload
  python3
)

for c in "${commands[@]}"
  do
    if (! (command -v "$c" > /dev/null)); then
      echo "Installing $c ..."
      sudo pacman -S "$c"
    fi
  done

# Install Neovim
if (! (command -v nvim > /dev/null)); then
  echo "Installing Neovim ..."
  sudo pacman -S neovim
fi


# link rofi
mv ~/.config/rofi ~/.dotfiles_bkp/
ln -sf ~/.dotfiles/rofi ~/.config

mv ~/.config/alacritty ~/.dotfiles_bkp/
ln -sf ~/.dotfiles/alacritty ~/.config
