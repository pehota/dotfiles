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
fi

commands=(
  git
  python3
  tmux
  reattach-to-user-namespace
  urlview
  rg
  exa
  shellcheck
)


for c in "${commands[@]}"
  do
    if (! (command -v "$c" > /dev/null)); then
      echo "Installing $c ..."
      brew install "$c"
    fi
  done

# Install Neovim
if (! (command -v nvim > /dev/null)); then
  echo "Installing Neovim ..."
  brew install neovim
fi

# Configure git to use the credentials from the keychain
git config --global credential.helper osxkeychain
