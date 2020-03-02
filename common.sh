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

if [[ ! -f ~/.dotfiles/backup/init.vim ]]; then
  if [[ ! -d ~/.config/nvim ]]; then
    mkdir -p ~/.config/nvim
    touch ~/.config/nvim/init.vim
  else
    cp ~/.config/nvim/init.vim ~/.dotfiles/backup/
  fi
  echo "source ~/.dotfiles/vimrc" >> ~/.config/nvim/init.vim
fi

[ ! -L ~/.config/nvim/coc-settings.json ] && {
  mv ~/.config/nvim/coc-settings.json ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/coc-settings.json ~/.config/nvim
}


# Rerun plug installation on nvim
echo "Installing nvim plugins ..."
nvim --noplugin --headless +PlugInstall +qall

. ./nvm.sh
# Install the tmux plugins if tmux is running (highly unlikely)
if [ -n "$TMUX" ]; then
  . ~/.tmux/plugins/tpm/bindings/install_plugins
else
  echo "Install tmux plugins by running: . ~/.tmux/plugins/tpm/bindings/install_plugins"
fi
