#!/bin/bash

if (! (command -v docker &> /dev/null)); then
  echo "Installing docker ..."
  pamac install --no-confirm docker
fi

if (! (command -v docker-compose &> /dev/null)); then
  echo "Installing docker-compose ..."
  pamac install --no-confirm docker-compose
fi

echo "Fixing docker permissions ..."
sudo gpasswd -a "$(whoami)" docker
sudo groupadd -f docker || true
sudo usermod -aG docker "$(whoami)"

echo "Enabling docker service ..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Done"
