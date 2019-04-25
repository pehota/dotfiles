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

if (! (command -v pip > /dev/null) ); then
  echo "Installing pip ..."
  sudo easy_install pip
fi

if (! (pip list --format=columns | grep pynvim > /dev/null)); then
  pip install --upgrade --user pynvim || echo "Install python3-neovim manually"
fi

if [[ ! -f ~/.dotfiles_bkp/init.vim ]]; then
  if [[ ! -d ~/.config/nvim ]]; then
    mkdir -p ~/.config/nvim
    touch ~/.config/nvim/init.vim
  else
    cp ~/.config/nvim/init.vim ~/.dotfiles_bkp/
  fi
  echo "source ~/.dotfiles/vimrc" >> ~/.config/nvim/init.vim
fi

# Rerun plug installation on nvim
echo "Installing nvim plugins ..."
nvim --noplugin +PlugInstall +qall

# Install nvm
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

# Install the tmux plugins if tmux is running (highly unlikely)
if [ -n "$TMUX" ]; then
  . ~/.tmux/plugins/tpm/bindings/install_plugins
else
  echo "Install tmux plugins by running: . ~/.tmux/plugins/tpm/bindings/install_plugins"
fi
