#!/usr/bin/env bash

#Git
mkdir -p ~/.dotfiles_bkp

mv ~/.gitconfig ~/.dotfiles_bkp/.gitconfig
ln -sf ~/.dotfiles/copy/gitconfig ~/.gitconfig

mv ~/.gitignore ~/.dotfiles_bkp/.gitignore
ln -sf ~/.dotfiles/copy/gitignore ~/.gitignore

ln -sf ~/.dotfiles/copy/git-prompt.sh ~/.git-prompt.sh

# Tmux
mv ~/.tmux.conf ~/.dotfiles_bkp/.tmux.conf
ln -sf ~/.dotfiles/copy/tmux.conf ~/.tmux.conf
ln -sf ~/.dotfiles/copy/tmux ~/.tmux


# Neovim
mv ~/.vimrc ~/.dotfiles_bkp/.vimrc
ln -sf ~/.dotfiles/copy/vimrc ~/.vimrc
