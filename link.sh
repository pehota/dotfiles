#!/usr/bin/env bash

# Create a backup folder where all existing dotfiles will be saved to
mkdir -p ~/.dotfiles/.backup

#Bash
[ ! -L ~/.bash_profile ] && {
  mv ~/.bash_profile ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/bash_profile ~/.bash_profile
}

if [ -s ~/.bashrc ]; then
  echo "source ~/.bash_profile" >> ~/.bashrc
fi

#Git
[ ! -L ~/.gitconfig ] && {
  mv ~/.gitconfig ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
}

[ ! -L ~/.gitignore ] && {
  mv ~/.gitignore ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/gitignore ~/.gitignore
}

[ ! -L  ~/.git_templates ] && {
  mv ~/.git_templates ~/.dotfiles/.backup/ &> /dev/null
  ln -s ~/.dotfiles/git_templates ~/.git_templates
}

[ ! -L  ~/.config/kitty ] && {
  mv ~/.config/kitty ~/.dotfiles/.backup/ &> /dev/null
  ln -s ~/.dotfiles/kitty ~/.config
}

# Tmux
[ ! -L ~/.tmux.conf ] && {
  mv ~/.tmux.conf ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/tmux.conf ~/.tmux.conf
}

[ ! -L ~/.tmux ] && {
  mv ~/.tmux ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/tmux ~/.tmux
}

# Neovim
[ ! -L ~/.vimrc ] && {
  mv ~/.vimrc ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/vimrc ~/.vimrc
}

# ctags
[ ! -L ~/.ctags.d ] && {
  mv ~/.ctags.d ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/ctags.d ~/.ctags.d
}

# cmus
[ ! -L  ~/.config/cmus ] && {
  mv ~/.config/cmus ~/.dotfiles/.backup/ &> /dev/null
  ln -sf ~/.dotfiles/cmus ~/.config
}
