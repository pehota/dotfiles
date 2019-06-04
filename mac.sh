#!/usr/bin/env bash

# Install the font for Powerline
if [ ! -f "/Users/$(whoami)/Library/Fonts/Droid Sans Mono for Powerline Nerd Font Complete.otf" ]; then
  cp "$HOME/.dotfiles/Droid Sans Mono for Powerline Nerd Font Complete.otf" "/Users/$(whoami)/Library/Fonts"
fi

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

declare -A commands_map=(
["git"]="git"
["curl"]="curl"
["tmux"]="tmux"
["exa"]="exa"
["python3"]="python3"
["nvim"]="neovim"
["rg"]="ripgrep"
["reattach-to-user-namespace"]="reattach-to-user-namespace"
["urlview"]="urlview"
["shellcheck"]="shellcheck"
["cmus"]="cmus"
)


declare -A cask_commands_map=(
["karabiner-elements"]="karabiner-elements"
["kitty"]="kitty"
["alacritty"]="alacritty"
)

commands_to_install=""
cask_commands_to_install=""

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

for c in "${!cask_commands_map[@]}"
do
  if (! (command -v "$c" &> /dev/null)); then
    if [[ -n "$cask_commands_to_install" ]]; then
      cask_commands_to_install="$cask_commands_to_install ${cask_commands_map[$c]}"
    else
      cask_commands_to_install="${cask_commands_map[$c]}"
    fi
  fi
done

if [[ -n "$cask_commands_to_install" ]]; then
  echo "Installing $cask_commands_to_install"
  brew install "$cask_commands_to_install"
fi

[ ! -L  ~/.config/karabiner ] && {
  mv ~/.config/karabiner ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/karabiner ~/.config
}

# Configure git to use the credentials from the keychain
git config --global credential.helper osxkeychain

defaults write com.apple.finder AppleShowAllFiles YES
