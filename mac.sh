# Install the font for Powerline
cp ~/.dotfiles/Droid\ Sans\ Mono\ for\ Powerline\ Nerd\ Font\ Complete.otf /Users/$(whoami)/Library/Fonts

if (! (which brew > /dev/null) ); then
  echo "Installing brew ..."
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  echo "if [ -f \$(brew --prefix)/etc/bash_completion ]; then" >> ~/.bashrc
  echo " . \$(brew --prefix)/etc/bash_completion" >> ~/.bashrc
  echo "fi" >> ~/.bashrc
  echo "alias bup='brew update && brew upgrade && brew cleanup -s && brew doctor'" >> ~/.bashrc
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

# Configure git to use the credentials from the keychain
git config --global credential.helper osxkeychain


# Install nvm if necessary
if (!(command -v nvm > /dev/null)); then
  brew install nvm
  echo "source \$(brew --prefix nvm)/nvm.sh" >> ~/.bashrc
fi

# Install CMUS
if (! (which cmus > /dev/null) ); then
  echo "Installing CMUS ..."
  brew install cmus
fi
