[ -s ~/.profile ] && source ~/.profile # Load the default .profile

export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/.mongodb/bin:$PATH"
export PATH="$PATH:$HOME/.bin"
export PATH="$PATH:$HOME/.local/bin"

export EDITOR=nvim
# export TERM=screen-256color

# Git branch in prompt.
# Nicer bash prefix with git branch
export GIT_PS1_SHOWDIRTYSTATE=1
source ~/.dotfiles/git-prompt.sh
# Custom bash prompt via kirsle.net/wizards/ps1.html
PS1="\[$(tput bold)\]\[$(tput setaf 2)\]\[$(tput setaf 3)\]\w\$(__git_ps1 '\[\033[1;32;1m\] (%s)\[\033[0m\]')\[$(tput setaf 2)\]\\$ \[$(tput sgr0)\]"
export PS1

if [ -f "$(command -v exa)" ]; then
  alias ls='exa --group-directories-first'
fi

alias reboot-shell='source ~/.bash_profile'
alias tmux='tmux -2 -u'
alias cdg='cd ~/Work/job/git'
alias cdw='cd ~/Work'
alias ll='ls -al'
alias weather='curl -4 http://wttr.in/'
alias vimdiff='nvim -d'

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
source ~/.dotfiles/git-completion.bash

export PATH="$HOME/.cargo/bin:$PATH"

if [ "$DESKTOP_SESSION" = "i3" ]; then
  eval "$(ssh-agent -s)" &> /dev/null
  # export "$(gnome-keyring-daemon -s)"
  ssh-add ~/.ssh/*_rsa &> /dev/null
fi
