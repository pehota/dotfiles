#!/usr/bin/env bash

source ./utils.sh

#Bash
createSimlink bash_profile

if [ -s ~/.bashrc ]; then
  echo "source ~/.bash_profile" >> ~/.bashrc
fi

#Fish
createSimlink fish ~/.config

#Git
createSimlink gitconfig
createSimlink gititnore
createSimlink git_templates

# kitty
createSimlink kitty ~/.config

# Tmux
createSimlink tmux
createSimlink tmux.conf

# Neovim
createSimlink vimrc

# cmus
createSimlink cmus ~/.config
