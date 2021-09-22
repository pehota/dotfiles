#!/usr/bin/env bash

set -e

source ./utils.sh

if (! (isPackageInstalled fish)); then
  echo "Installing fish shell ..."
  installPackage fish
fi

# Install fish plugin manager
# We need to use `fish` in order to detect if the plugin manager is installed
PLUGIN_MANAGER_INSTALLED=$(fish -c "test (type -t fisher) = 'function'; and echo 1; or echo 0")

if [[ "$PLUGIN_MANAGER_INSTALLED" -ne "1" ]]; then
  echo "Installing fisher ..."
  fish -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
fi

# Install packages
fish -c "cat $WORKING_DIR/fish/fish_plugins | fisher install"

PATH_TO_SHELL_BIN=$(command -v fish)

# Add shell to allowed shells if needed
if (! (grep -q $PATH_TO_SHELL_BIN /etc/shells) ); then
  (echo $PATH_TO_SHELL_BIN | sudo tee -a /etc/shells) &> /dev/null
fi

# Set the default shell
if (test "$SHELL" != "$PATH_TO_SHELL_BIN"); then
  sudo chsh -s $PATH_TO_SHELL_BIN $(whoami) 
fi
