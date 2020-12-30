#!/usr/bin/env bash

source ./utils.sh

# Install common packages
declare -A packages=(
  ["bat"]="bat" # Improved cat
  ["cmus"]="cmus" # Music player
  ["curl"]="curl"
  ["exa"]="exa" # Improved ls
  ["fish"]="fish" # Friendly Interactive SHell
  ["git"]="git"
  ["kitty"]="kitty" # Terminal
  ["neomutt"]="neomutt" # Mail client
  ["nvim"]="neovim" # Vim Improved
  ["python3"]="python3" # needed for neovim
  ["rg"]="ripgrep" # fast file search
  ["shellcheck"]="shellcheck" # shell LSP
  ["tmux"]="tmux" # Terminal multiplexer
)
installPackages packages

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

createSimlink coc/settings.json ~/.config/nvim/coc-settings.json
createSimlink coc/extensions.json ~/.config/coc/extensions/package.json

# Rerun plug installation on nvim
echo "Installing nvim plugins ..."
nvim --noplugin --headless +PlugInstall +qall

if (isPackageInstalled "npm"); then
  echo "Installing coc extensions ..."
  cd  ~/.config/coc/extensions
  npm i > /dev/null
  cd $WORKING_DIR > /dev/null
  nvim --headless +CocUpdate +qall
else
  echo "Install coc extensions manually"
fi

# Install the tmux plugins if tmux is running (highly unlikely)
if [ -n "$TMUX" ]; then
  . ~/.tmux/plugins/tpm/bindings/install_plugins
else
  echo "Install tmux plugins by running: . ~/.tmux/plugins/tpm/bindings/install_plugins inside a tmux session"
fi
