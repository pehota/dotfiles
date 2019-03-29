#!/usr/bin/env bash

# Create a backup folder where all existing dotfiles will be saved to
mkdir -p ~/.dotfiles_bkp

#Bash
[ ! -L ~/.bash_profile ] && {
  mv ~/.bash_profile ~/.dotfiles_bkp/ &> /dev/null
  ln -sf ~/.dotfiles/bash_profile ~/.bash_profile
}

if [ -s ~/.bashrc ]; then
  echo "source ~/.bash_profile" >> ~/.bashrc
fi

#Git
[ ! -L ~/.gitconfig ] && {
  mv ~/.gitconfig ~/.dotfiles_bkp/ &> /dev/null
  ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
}

[ ! -L ~/.gitignore ] && {
  mv ~/.gitignore ~/.dotfiles_bkp/ &> /dev/null
  ln -sf ~/.dotfiles/gitignore ~/.gitignore
}

[ ! -L  ~/.git_templates ] && {
  mv ~/.git_templates ~/.dotfiles_bkp/ &> /dev/null
  ln -s ~/.dotfiles/git_templates ~/.git_templates
}

[ ! -L  ~/.config/kitty ] && {
  mv ~/.config/kitty ~/.dotfiles_bkp/ &> /dev/null
  ln -s ~/.dotfiles/kitty ~/.config
}

# Tmux
[ ! -L ~/.tmux.conf ] && {
  mv ~/.tmux.conf ~/.dotfiles_bkp/ &> /dev/null
  ln -sf ~/.dotfiles/tmux.conf ~/.tmux.conf
}

[ ! -L ~/.tmux ] && {
  mv ~/.tmux ~/.dotfiles_bkp/ &> /dev/null
  ln -sf ~/.dotfiles/tmux ~/.tmux
}

# Neovim
[ ! -L ~/.vimrc ] && {
  mv ~/.vimrc ~/.dotfiles_bkp/ &> /dev/null
  ln -sf ~/.dotfiles/vimrc ~/.vimrc
}

# ctags
[ ! -L ~/.ctags.d ] && {
  mv ~/.ctags.d ~/.dotfiles_bkp/ &> /dev/null
  ln -sf ~/.dotfiles/ctags.d ~/.ctags.d
}

# cmus
[ ! -L  ~/.config/cmus ] && {
  mv ~/.config/cmus ~/.dotfiles_bkp/ &> /dev/null
  ln -sf ~/.dotfiles/cmus ~/.config
}
