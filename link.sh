#!/usr/bin/env bash

# Create a backup folder where all existing dotfiles will be saved to
mkdir -p ~/.dotfiles_bkp

#Git
mv ~/.gitconfig ~/.dotfiles_bkp/
ln -sf ~/.dotfiles/gitconfig ~/.gitconfig

mv ~/.gitignore ~/.dotfiles_bkp/
ln -sf ~/.dotfiles/gitignore ~/.gitignore

mv ~/.git-prompt.sh ~/.dotfiles_bkp/
ln -sf ~/.dotfiles/git-prompt.sh ~/.git-prompt.sh

ln -sf ~/.dotfiles/git_templates ~/.git_templates

# Tmux
mv ~/.tmux.conf ~/.dotfiles_bkp/.tmux.conf
ln -sf ~/.dotfiles/tmux.conf ~/.tmux.conf
# ln -s ~/.dotfiles/tmux ~/.tmux


# Neovim
mv ~/.vimrc ~/.dotfiles_bkp/
ln -sf ~/.dotfiles/vimrc ~/.vimrc

# ctags
ln -sf ~/.dotfiles/ctags.d ~/.ctags.d
