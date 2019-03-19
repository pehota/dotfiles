# Install the font for Powerline
cp ~/.dotfiles/Droid\ Sans\ Mono\ for\ Powerline\ Nerd\ Font\ Complete.otf /usr/share/fonts


# Configure git to use the credentials from the keyring
# Install the keyring if necessary
if (! (which libgnome-keyring-dev > /dev/null) ); then
  sudo pacman -S libgnome-keyring-dev
  sudo make --directory=/usr/share/doc/git/contrib/credential/gnome-keyring
fi
git config --global credential.helper /usr/share/doc/git/contrib/credential/gnome-keyring/git-credential-gnome-keyring


if (! (which rofi > /dev/null) ); then
  echo "Instaling rofi ..."
  sudo pacman -S rofi
fi
