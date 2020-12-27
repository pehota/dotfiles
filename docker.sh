#!/bin/bash

if (! (command -v docker &> /dev/null) ); then
  echo "Installing docker ..."
  pamac install docker
fi

if (! (command -v docker-compose &> /dev/null) ); then
  echo "Installing docker-compose ..."
  pamac install docker-compose
fi

if (! (command -v ctop &> /dev/null) ); then
  echo "Installing ctop ..."
  pamac install ctop
fi

echo "Fixing docker permissions ..."
sudo gpasswd -a "$(whoami)" docker
sudo groupadd -f docker || true
sudo usermod -aG docker "$(whoami)"

echo "Enabling docker service ..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Done"
