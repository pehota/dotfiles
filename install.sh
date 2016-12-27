#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=$HOME/.dotfiles                    # dotfiles directory
olddir=$HOME/.dotfiles_bkp             # old dotfiles backup directory
# files="bashrc vimrc vim zshrc oh-my-zsh"    # list of files/folders to symlink in homedir

##########

# create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks 
# for file in $files; do
for location in $(find $dir -maxdepth 1 -name '*' ! -path '*.git'| sort); do
  file=$(basename $location)
  if [[ $file =~ ^\. || $file == $(basename "$0") ]]; then
    continue;
  fi

  echo "Moving any existing dotfiles $file to $olddir"
  mv -f $HOME/.$file $olddir 
  echo "Creating symlink to $file in home directory."
  ln -s $dir/$file ~/.$file
done
