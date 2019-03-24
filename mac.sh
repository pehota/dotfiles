#!/usr/bin/env bash

# Install the font for Powerline
cp "$HOME/.dotfiles/Droid Sans Mono for Powerline Nerd Font Complete.otf" "/Users/$(whoami)/Library/Fonts"

if (! (command -v brew > /dev/null) ); then
  echo "Installing brew ..."

  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  {
    echo "if [ -f \$(brew --prefix)/etc/bash_completion ]; then"
    echo "  . \$(brew --prefix)/etc/bash_completion"
    echo "fi"
    echo "alias bup='brew update && brew upgrade && brew cleanup -s && brew doctor'"
  } >> ~/.bashrc
else
  echo "Brew is already installed"
fi

commands=(
  git
  python3
  neovim
  tmux
  reattach-to-user-namespace
  urlview
  nvm
  rg
  exa
)


for c in "${commands[@]}"
  do
    if (! (command -v "$c" > /dev/null)); then
      echo "Installing $c ..."
      brew install "$c"
    fi
  done

if (! (command -v pip3 > /dev/null) ); then
  echo "Installing pip ..."
  sudo easy_install3 pip3
fi

if (! (pip3 list --format=columns | grep neovim)); then
  pip3 install --user --upgrade pynvim || echo "Install python3-neovim manually"
fi

# Configure git to use the credentials from the keychain
git config --global credential.helper osxkeychain
