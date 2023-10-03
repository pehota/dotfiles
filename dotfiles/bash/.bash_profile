[ -s ~/.profile ] && source ~/.profile # Load the default .profile

export PATH="/usr/local/sbin:$PATH"
export PATH="$HOME/.mongodb/bin:$PATH"
export PATH="$PATH:$HOME/.bin"
export PATH="$PATH:$HOME/.local/bin"

export EDITOR=nvim

if [ -f "$(command -v eza)" ]; then
	alias ls='eza --group-directories-first'
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
	eval "$(ssh-agent -s)" &>/dev/null
	# export "$(gnome-keyring-daemon -s)"
	ssh-add ~/.ssh/*_rsa &>/dev/null
fi
