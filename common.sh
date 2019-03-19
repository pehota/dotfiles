# Install the tmux plugin manager
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install vim-plug
curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Rerun plug installation on nvim
nvim +PlugInstall +qall

# Install nvm if necessary
if [[ ! -d ~/.nvm ]]; then
  echo "Linking nvm ..."

  mkdir ~/.nvm

  echo "export NVM_DIR=\"\$HOME/.nvm\"" >> ~/.bashrc

  source ~/.bashrc
fi

echo "Installing node.js ..."
nvm install stable
