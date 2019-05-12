#!/usr/bin/env bash

# Install nvm
if (! (command -v nvm > /dev/null)); then
  "Installing nvm ..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
fi

if [[ ! -d ~/.nvm ]]; then
  echo "Linking nvm ..."
  mkdir ~/.nvm
fi

# Export NVM_DIR and add nvm loading
if [[ -z "$NVM_DIR" ]]; then
  echo "Update NVM_DIR ..."
  {
    echo "export NVM_DIR=\"\$HOME/.nvm\""
    echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"  # This loads nvm"
    echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"  # This loads nvm bash_completion"
  } >> ~/.bash_profile

  export NVM_DIR=~/.nvm

  if (! (command -v nvm > /dev/null) ); then
    # shellcheck disable=SC1090
    [ -s ~/.nvm/nvm.sh ] && . ~/.nvm/nvm.sh  # This loads nvm"
    # shellcheck disable=SC1090
    [ -s ~/.nvm/bash_completion ] && . ~/.nvm/bash_completion  # This loads nvm bash_completion
  fi
fi

if (! (command -v nvm > /dev/null)); then
  printf "NVM and node should be installed manually\n"
else
  echo "Installing node.js ..."
  nvm install stable
fi
