[[ -s "$HOME/.profile" ]] && source "$HOME/.profile" # Load the default .profile

export PATH="/usr/local/sbin:$PATH"
export PATH=$PATH:/Applications/Postgres.app/Contents/Versions/latest/bin
export PATH="$HOME/.mongodb/bin:$PATH"

eval "$(thefuck --alias)"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

if [ -f $(brew --prefix)/etc/bash_completion ]; then
    . $(brew --prefix)/etc/bash_completion
fi

export EDITOR=nvim
export NVM_DIR="$HOME/.nvm"
. "$(brew --prefix nvm)/nvm.sh"
export TERM=screen-256color

# Git branch in prompt.
# Nicer bash prefix with git branch
GIT_PS1_SHOWDIRTYSTATE=1
source ~/.git-prompt.sh
# Custom bash prompt via kirsle.net/wizards/ps1.html
export PS1="\[$(tput bold)\]\[$(tput setaf 2)\]\[$(tput setaf 3)\]\w\$(__git_ps1 '\[\033[1;35;1m\] (%s)\[\033[0m\]')\[$(tput setaf 2)\]\\$ \[$(tput sgr0)\]"

alias bup='brew update && brew upgrade && brew cleanup -s && brew doctor'
alias reboot-shell='source ~/.bash_profile'
alias tmux='tmux -2'
alias f*='fuck'
alias vim='vim -u ~/.dotfiles/vim/vimrc'
alias cdg='cd ~/Work/Shore/git'
alias cdw='cd ~/Work'
