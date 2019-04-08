#!/bin/bash
set -e

declare -A commands_map=(
  ["dunst"]="dunst"
  ["compton"]="compton"
  ["i3status-rs"]="i3status-rust-git"
)

commands_to_install=""

for c in "${!commands_map[@]}"
do
	if (! (command -v "$c" &> /dev/null)); then
		if [[ -n "$commands_to_install" ]]; then
			commands_to_install="$commands_to_install ${commands_map[$c]}"
		else
			commands_to_install="${commands_map[$c]}"
		fi
	fi
done

if [[ -n "$commands_to_install" ]]; then
  echo "Installing $commands_to_install"
  yes | sudo pacman -Sy $commands_to_install
fi

if [ ! -L ~/.config/i3 ]; then
  ln -sf ~/.dotfiles/i3 ~/.config
fi

if [ ! -L ~/.config/compton ]; then
  ln -sf ~/.dotfiles/compton ~/.config
fi

if [ -n "$TERMINAL" ]; then
  echo "Adding \$TERMINAL environment variable which requires \`sudo\`"
  {
    echo "export TERMINAL=kitty" | sudo tee -a /etc/environment
  } >> /dev/null
fi

{
  echo "if [ \"\$DESKTOP_SESSION\" = \"i3\" ]; then"
  echo "  export \"\$(gnome-keyring-daemon --start --components=secrets,ssh)\""
  echo "fi"
  echo ""
} >> ~/.bash_profile
