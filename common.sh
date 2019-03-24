#!/usr/bin/env bash

# Install the tmux plugin manager
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install vim-plug
if [[ ! -f ~/.local/share/nvim/site/autoload/plug.vim ]]; then
  echo "Installing vim-plug ..."
  curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if [[ ! -f ~/.config/nvim/init.vim.orig ]]; then
  cp -T ~/.config/nvim/init.vim ~/.config/nvim/init.vim.orig
  echo "source ~/.dotfiles/vimrc" >> ~/.config/nvim/init.vim
fi

# Rerun plug installation on nvim
echo "Installing nvim plugins ..."
nvim +PlugInstall +qall

# Install nvm
if [[ ! -d ~/.nvm ]]; then
  echo "Linking nvm ..."
  mkdir ~/.nvm
fi

# Export NVM_DIR and add nvm loading
if [[ -n "$NVM_DIR" ]]; then
  echo "Update NVM_DIR ..."
  {
    echo "export NVM_DIR=\"\$HOME/.nvm\""
    echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"  \# This loads nvm"
    echo "[ -s \"\$NVM_DIR/bash_completion\" ] && \. \"\$NVM_DIR/bash_completion\"  \# This loads nvm bash_completion"
  } >> ~/.bash_profile

  export NVM_DIR=~/.nvm

  if (! (command -v nvm > /dev/null) ); then
    # shellcheck disable=SC1090
    [ -s ~/.nvm/nvm.sh ] && . ~/.nvm/nvm.sh  # This loads nvm"
    # shellcheck disable=SC1090
    [ -s ~/.nvm/bash_completion ] && . ~/.nvm/bash_completion  # This loads nvm bash_completion
  fi
fi

echo "Installing node.js ..."
nvm install stable
