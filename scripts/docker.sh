#!/usr/bin/env bash

set -e

source ./utils.sh

declare -A packages=(
  ["docker"]="docker-bin"
  ["docker-compose"]="docker-compose-bin"
  ["ctop"]="ctop-bin"
)

installPackages packages

if (! (command -v ctop &> /dev/null) ); then
  echo "Installing ctop ..."
  pamac install ctop
fi

echo "Fixing docker permissions ..."
sudo gpasswd -a "$(whoami)" docker
sudo groupadd -f docker || true
sudo usermod -aG docker "$(whoami)"
echo "User '$(whoami)' will have to log out and log in again in order for permissions to take effect.\n"

echo "Enabling docker service ..."
sudo systemctl enable --now docker

echo "Done.\n"
