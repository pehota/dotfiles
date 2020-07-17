#!/usr/bin/env bash

sudo fallocate -l 8G /swapfile
sudo mkswap /swapfile
sudo chmod u=rw,go= /swapfile
sudo swapon /swapfile
echo "/swapfile none swap defaults 0 0" | sudo tee -a  /etc/fstab
