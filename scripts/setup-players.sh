#!/usr/bin/env bash

source ./utils.sh

declare -A packages=(
	["spotifyd"]="spotifyd"
	["spt"]="spotify-tui-bin"
)

installPackages packages

# link spotifyd config
createSimlink spotifyd ~/.config

# link spotifyd service
createSimlink spotifyd.service ~/.config/systemd/user/

# enable spotifyd service
systemctl --user status spotifyd.service 2&>1 /dev/null

if [[ -n "$?" ]]; then
	echo "Installing spotifyd service ..."
	systemctl --user enable --now spotifyd.service
fi
