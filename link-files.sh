#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=$HOME/.dotfiles                    # dotfiles directory
dstdir=$HOME                           # folder to copy the files to
olddir=$dstdir/.dotfiles_bkp           # old dotfiles backup directory
##########

# create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles in $dir"
mkdir -p $olddir
echo "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
# for file in $files; do
for location in $(find "$dir/copy" -maxdepth 1 -name '*' ! -path '*.git'| sort); do
  file=$(basename $location)

  if [[ "copy" == $file ]]; then
    continue;
  fi

  if [[ -L $dstdir/.$file ]]; then
    continue;
  fi

  if [[ -e $dstdir/.$file ]]; then
    echo "Moving .$file to $olddir"

    if [[ -d $dstdir/.$file ]]; then
      mv -f $dstdir/.$file -t="$olddir/"
    else
      mv -f $dstdir/.$file $olddir
    fi
  fi

  echo "Creating symlink to $dir/copy/$file in $dstdir/.$file"
  ln -s $dir/copy/$file $dstdir/.$file
done

for location in $(find "$dir/merge" -maxdepth 1 -name '*' ! -path '*.git'| sort); do
  dirToMerge=$(basename $location)

  if [[ "merge" == $dirToMerge ]]; then
    continue;
  fi

  for fileInDir in $(find "$location" -maxdepth 1 -name '*' ! -path '*.git'| sort); do
    fileToMerge=$(basename $fileInDir)
    destination=$dstdir/.$dirToMerge/$fileToMerge;
    backupDir=$olddir/$dirToMerge;

    if [[ $dirToMerge == $fileToMerge ]]; then
      continue;
    fi

    if [[ ! -d $(dirname $destination) ]]; then
      mkdir -p $(dirname $destination);
    fi

    if [[ -L $destination ]]; then
      continue;
    fi

    if [[ -e $destination  ]]; then
      echo "Moving $destination to $backupDir"
      mkdir -p $backupDir;
      mv -f $destination $backupDir;
    fi
    echo "Creating symlink to $fileInDir in home $destination"
    ln -s $fileInDir $destination
  done
done

if [[ -d $dstdir/.config/nvim ]]; then
  ln -s $dstdir/.vimrc $dstdir/.config/nvim/init.vim
fi

cd $dir > /dev/null

echo "Done"
