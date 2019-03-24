#!/usr/bin/env bash

# Create a backup folder where all existing dotfiles will be saved to
mkdir -p ~/.dotfiles_bkp

#Git
mv ~/.gitconfig ~/.dotfiles_bkp/.gitconfig
ln -s ~/.dotfiles/gitconfig ~/.gitconfig

mv ~/.gitignore ~/.dotfiles_bkp/.gitignore
ln -s ~/.dotfiles/gitignore ~/.gitignore

ln -s ~/.dotfiles/git-prompt.sh ~/.git-prompt.sh

ln -s ~/.dotfiles/git_templates ~/.git_templates

# Tmux
mv ~/.tmux.conf ~/.dotfiles_bkp/.tmux.conf
ln -s ~/.dotfiles/tmux.conf ~/.tmux.conf
# ln -s ~/.dotfiles/tmux ~/.tmux


# Neovim
mv ~/.vimrc ~/.dotfiles_bkp/.vimrc
ln -s ~/.dotfiles/vimrc ~/.vimrc

# ctags
ln -s ~/.dotfiles/ctags.d ~/.ctags.d

# Bash
echo "source ~/.dotfiles/bashrc" >> ~/.bashrc
