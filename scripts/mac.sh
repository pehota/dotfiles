#!/usr/bin/env bash

source ./utils.sh

if (! (isPackageInstalled "brew") ); then
  echo "Installing brew ..."

  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  {
    echo "if [ -f \$(brew --prefix)/etc/bash_completion ]; then"
    echo "  . \$(brew --prefix)/etc/bash_completion"
    echo "fi"
    echo "alias bup='brew update && brew upgrade && brew cleanup -s && brew doctor'"
  } >> ~/.bashrc
fi

installPackage "homebrew/cask-fonts/font-fira-code-nerd-font"

declare -A packages=(
  ["fnm"]="Schniz/tap/fnm" # Fast Node Manager - nvm replacement
  ["reattach-to-user-namespace"]="reattach-to-user-namespace"
  ["urlview"]="urlview"
)
installPackages packages

declare -A cask_packages=(
  ["karabiner-elements"]="karabiner-elements"
  ["kitty"]="kitty"
  ["alacritty"]="alacritty"
)
installPackages cask_packages

createSimlink karabiner ~/.config

# Configure git to use the credentials from the keychain
git config --global credential.helper osxkeychain

defaults write com.apple.finder AppleShowAllFiles YES
