#!/bin/bash
set -e

DOTFILES_DIR=~/.dotfiles
DST_DIR=$HOME

HOST_OS=$(uname)

function checkOs {
  if [[ $HOST_OS == "$1" ]]; then
    echo true
  else
    echo false
  fi
}

IS_MAC=$(checkOs "Darwin")
IS_LINUX=$(checkOs "Linux")

tmuxinatorCompletionPath=~/.bin/tmuxinator.bash

if [[ ! $IS_MAC && ! $IS_LINUX  ]]; then
  echo "Unsupported OS"
  exit 1
fi

# Install brew if necessary
if [[ $IS_MAC ]]; then
  if (! (which brew > /dev/null) ); then
    echo "Installing brew ..."
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
fi

# Install git if necessary
if (! (which git > /dev/null) ); then
  if [[ $IS_MAC ]]; then
    brew install git
  else
    sudo apt install git-all
  fi
fi

# Install nvim if necessary
if (! (which nvim > /dev/null) ); then
  if [[ $IS_MAC ]]; then
    brew install neovim
  else
    sudo apt-get -y install software-properties-common
    sudo add-apt-repository ppa:neovim-ppa/stable
    sudo apt-get -y update
    sudo apt-get -y install neovim python-dev python-pip python3-dev python3-pip
  fi

fi


if (! (which pip > /dev/null) ); then
  sudo easy_install pip
fi

# pip install python-neovim
# pip3 install python3-neovim

# Install vimrc.js if necessary
if [[ ! -d ~/.vimrc.js ]]; then
  curl -o- https://raw.githubusercontent.com/zperrault/vimrc.js/master/install.sh | bash
fi

# Install tmux if necessary
if (! (which tmux > /dev/null) ); then
  if [[ $IS_MAC ]]; then
    brew install tmux reattach-to-user-namespace urlview
  else
    sudo apt-get install tmux urlview
  fi
fi

# Install the tmux plugin manager
if [[ ! -d $DST_DIR/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm "$DST_DIR"/.tmux/plugins/tpm
fi

# Install tmuxinator if necessary
if (! (which tmuxinator > /dev/null) ); then
  sudo gem install tmuxinator
  mkdir ~/.bin
  sudo curl -o $tmuxinatorCompletionPath https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.bash
fi

# clone the .dotfiles repo
if [[ ! -d $DOTFILES_DIR  ]]; then
  git clone --quiet https://github.com/pehota/dotfiles.git $DOTFILES_DIR
fi

. "$DOTFILES_DIR/link-files.sh"

# Rerun plug installation on nvim
nvim +PlugInstall +qall

echo "source $tmuxinatorCompletionPath" >> ~/.bash_profile

if [[ $IS_MAC ]]; then
  echo "if [ -f \$(brew --prefix)/etc/bash_completion ]; then" >> ~/.bash_profile
  echo " . \$(brew --prefix)/etc/bash_completion" >> ~/.bash_profile
  echo "fi" >> ~/.bash_profile
  echo "alias bup='brew update && brew upgrade && brew cleanup -s && brew doctor'" >> ~/.bash_profile
fi

if [[ -d "/Applications/Postgres.app/Contents/Versions/latest/bin" ]]; then
  echo "export PATH=\$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin" >> ~/.bash_profile
fi

if [[ $IS_MAC ]]; then
  # if (git credential-osxkeychain); then
  git config --global credential.helper osxkeychain
else
  # Install the keyring if necessary
  if (! (which libgnome-keyring-dev > /dev/null) ); then
    sudo apt-get -y install libgnome-keyring-dev
    sudo make --directory=/usr/share/doc/git/contrib/credential/gnome-keyring
  fi
  git config --global credential.helper /usr/share/doc/git/contrib/credential/gnome-keyring/git-credential-gnome-keyring
fi

# Install nvm if necessary
if [[ ! -d ~/.nvm ]]; then
  echo "Installling nvm ..."

  mkdir ~/.nvm

  echo "export NVM_DIR=\"\$HOME/.nvm\"" >> ~/.bash_profile

  if [[ $IS_MAC ]]; then
    brew install nvm
    echo "source \$(brew --prefix nvm)/nvm.sh" >> ~/.bash_profile
  else
    sudo apt-get install build-essential libssl-dev
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.4/install.sh | bash
    echo "[[ -s \$HOME/.nvm/nvm.sh ]] && . \$HOME/.nvm/nvm.sh  # This loads NVM" >> ~/.bash_profile
  fi

  source ~/.bash_profile
fi

if (! (which node > /dev/null) ); then
  echo "Installing node.js ..."
  nvm install stable
fi

#Install Elm
if (! (which elm > /dev/null) ); then
  echo "Installing elm ..."
  npm install -g elm
fi

if (! (which elm-format > /dev/null) ); then
  echo "Installing elm-format ..."
  npm install -g elm-format
fi

# Install CMUS
if (! (which cmus > /dev/null) ); then
  echo "Installing CMUS ..."
  if [[ $IS_MAC  ]]; then
    brew install cmus
  else
    sudo apt-get install cmus
  fi
fi


echo "Done"
