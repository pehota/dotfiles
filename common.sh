#!/usr/bin/env bash

mkdir -p ~/.dotfiles/.backup

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

if (! (isPackageInstalled pip) ); then
  echo "Installing pip ..."
  sudo easy_install pip
fi

if (! (pip list --format=columns | grep pynvim > /dev/null)); then
  pip install --upgrade --user pynvim || echo "Install python3-neovim manually"
fi

if [[ ! -f ~/.dotfiles/.backup/init.vim ]]; then
  if [[ ! -d ~/.config/nvim ]]; then
    mkdir -p ~/.config/nvim
    touch ~/.config/nvim/init.vim
  else
    cp ~/.config/nvim/init.vim ~/.dotfiles/.backup/
  fi
  echo "source ~/.dotfiles/vimrc" >> ~/.config/nvim/init.vim
fi

[ ! -L ~/.config/nvim/coc-settings.json ] && {
  if [[ -f ~/.config/nvim/coc-settings.json ]]; then
    mv ~/.config/nvim/coc-settings.json ~/.dotfiles/.backup/ &> /dev/null
  fi
  ln -sf ~/.dotfiles/coc/settings.json ~/.config/nvim/coc-settings.json
}

[ ! -L ~/.config/coc/extensions/package.json ] && {
  if [[ ! -d ~/.config/coc/extensions ]]; then
    mkdir -p ~/.config/coc/extensions
  fi

  if [[ -f ~/.config/coc/extensions/package.json ]]; then
    mv ~/.config/coc/extensions/package.json ~/.dotfiles/.backup/coc-extensions.json &> /dev/null
  fi
  ln -sf ~/.dotfiles/coc/extensions.json ~/.config/coc/extensions/package.json
}

# Rerun plug installation on nvim
echo "Installing nvim plugins ..."
nvim --noplugin --headless +PlugInstall +qall

echo "Installing coc extensions ..."
nvim --headless +CocInstall +qall

# Install the tmux plugins if tmux is running (highly unlikely)
if [ -n "$TMUX" ]; then
  . ~/.tmux/plugins/tpm/bindings/install_plugins
else
  echo "Install tmux plugins by running: . ~/.tmux/plugins/tpm/bindings/install_plugins inside a tmux session"
fi
