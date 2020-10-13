#!/usr/bin/env bash

set -e

source ./utils.sh

if (! (isPackageInstalled fish)); then
  echo "Installing fish shell ..."
  installPackage fish
fi

# Install oh-my-fish if needed
# We need to use `fish` in order to detect if `omf` is installed
OMF_CHECK=$(fish -c "test (type -t omf); and echo 0; or echo 1")

if [[ "$OMF_CHECK" -ne "0" ]]; then
  echo "Installing oh-my-fish ..."
  curl -L https://get.oh-my.fish | fish
fi

# link oh-my-fish config
createSimlink omf ~/.config

# Install oh-my-fish packages
fish -c "omf install"

PATH_TO_SHELL_BIN=$(command -v fish)

# Add shell to allowed shells if needed
if (! (grep -q $PATH_TO_SHELL_BIN /etc/shells) ); then
  (echo $PATH_TO_SHELL_BIN | sudo tee -a /etc/shells) &> /dev/null
fi

# Set the default shell
if (test "$SHELL" != "$PATH_TO_SHELL_BIN"); then
  sudo chsh -s $PATH_TO_SHELL_BIN $(whoami) 
fi
