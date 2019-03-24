#!/usr/bin/env bash

# Install the font for Powerline
cp "$HOME/.dotfiles/Droid Sans Mono for Powerline Nerd Font Complete.otf" /usr/share/fonts


# Configure git to use the credentials from the keyring
# Install the keyring if necessary
if (! (command -v libgnome-keyring-dev > /dev/null) ); then
  sudo pacman -S libgnome-keyring-dev
  sudo make --directory=/usr/share/doc/git/contrib/credential/gnome-keyring
fi
git config --global credential.helper /usr/share/doc/git/contrib/credential/gnome-keyring/git-credential-gnome-keyring

commands=(
  alacritty
  preload
  rofi
)

for c in "${commands[@]}"
  do
    if (! (command -v "$c" > /dev/null)); then
      echo "Installing $c ..."
      sudo pacman -S "$c"
    fi
  done


# link rofi
mv ~/.config/rofi ~/.dotfiles_bkp/
ln -sf ~/.dotfiles/rofi ~/.config
