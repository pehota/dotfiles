[ -s ~/.profile ] && source ~/.profile # Load the default .profile
[ -s ~/.bashrc ] && source ~/.bashrc # Load the default .bashrc

export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/.mongodb/bin:$PATH"
export PATH="$PATH:$HOME/.bin"
export PATH="$PATH:$HOME/.local/bin"

[ -s ~/.rvm/scripts/rvm ] && source ~/.rvm/scripts/rvm # Load RVM into a shell session *as a function*

export EDITOR=nvim
# export TERM=screen-256color

# Git branch in prompt.
# Nicer bash prefix with git branch
export GIT_PS1_SHOWDIRTYSTATE=1
source ~/.git-prompt.sh
# Custom bash prompt via kirsle.net/wizards/ps1.html
PS1="\[$(tput bold)\]\[$(tput setaf 2)\]\[$(tput setaf 3)\]\w\$(__git_ps1 '\[\033[1;35;1m\] (%s)\[\033[0m\]')\[$(tput setaf 2)\]\\$ \[$(tput sgr0)\]"
export PS1

if [ -f "$(command -v exa)" ]; then
  alias ls='exa'
fi

alias reboot-shell='source ~/.bash_profile'
alias tmux='tmux -2'
alias cdg='cd ~/Work/Shore/git'
alias cdw='cd ~/Work'
alias ll='ls -al'
alias wmuc='curl -4 http://wttr.in/Munich'
alias wsof='curl -4 http://wttr.in/Sofia'
alias wcph='curl -4 http://wttr.in/Fredensborg'
alias wobnova='curl -4 http://wttr.in/Obnova'
alias weather='curl -4 http://wttr.in/'
alias vimdiff='nvim -d'

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

export PATH="$HOME/.rbenv/bin:$PATH"
[ -s rbenv ] && eval "$(rbenv init -)"
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"

export PATH="$HOME/.cargo/bin:$PATH"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
