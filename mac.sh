if (! (which brew > /dev/null) ); then
  echo "Installing brew ..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "Brew is already installed"
fi

if (! (which git > /dev/null) ); then
  brew install git
fi

if (! (which python > /dev/null) ); then
  echo "Installing python ..."
  brew install python
fi

if (! (which pip > /dev/null) ); then
  echo "Installing pip ..."
  sudo easy_install pip
fi

if (! (pip list --format=columns | grep neovim)); then
  pip install --user --upgrade pynvim || echo "Install pynvim manually"
fi

# Install python3 if necessary
if (! (which python3 > /dev/null) ); then
  echo "Installing python3 ..."
  brew install python3
fi

if (! (which pip3 > /dev/null) ); then
  echo "Installing pip ..."
  sudo easy_install3 pip3
fi

if (! (pip3 list --format=columns | grep neovim)); then
  pip3 install --user --upgrade pynvim || echo "Install python3-neovim manually"
fi

# Install nvim if necessary
if (! (which nvim > /dev/null) ); then
  echo "Installing Neovim ..."
  brew install neovim
fi

# Install tmux if necessary
if (! (which tmux > /dev/null) ); then
  brew install tmux reattach-to-user-namespace urlview
fi

echo "if [ -f \$(brew --prefix)/etc/bash_completion ]; then" >> ~/.dotfiles/bashrc
echo " . \$(brew --prefix)/etc/bash_completion" >> ~/.dotfiles/bashrc
echo "fi" >> ~/.dotfiles/bashrc
echo "alias bup='brew update && brew upgrade && brew cleanup -s && brew doctor'" >> ~/.dotfiles/bashrc
