#!/usr/bin/env bash

# Create a backup folder where all existing dotfiles will be saved to
mkdir -p ~/.dotfiles_bkp

#Git
mv ~/.gitconfig ~/.dotfiles_bkp/.gitconfig
ln -s ~/.dotfiles/copy/gitconfig ~/.gitconfig

mv ~/.gitignore ~/.dotfiles_bkp/.gitignore
ln -s ~/.dotfiles/copy/gitignore ~/.gitignore

ln -s ~/.dotfiles/copy/git-prompt.sh ~/.git-prompt.sh

ln -s ~/.dotfiles/copy/git_templates ~/.git_templates

# Tmux
mv ~/.tmux.conf ~/.dotfiles_bkp/.tmux.conf
ln -s ~/.dotfiles/copy/tmux.conf ~/.tmux.conf
ln -s ~/.dotfiles/copy/tmux ~/.tmux


# Neovim
mv ~/.vimrc ~/.dotfiles_bkp/.vimrc
ln -s ~/.dotfiles/copy/vimrc ~/.vimrc

# ctags
ln -s ~/.dotfiles/copy/ctags.d ~/.ctags.d

# Bash
echo "source ~/.dotfiles/bashrc" >> ~/.bashrc
