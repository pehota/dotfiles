#!/usr/bin/env bash

if [[ ! -d ~/.config/ranger/plugins/ranger_devicons ]]; then
  echo "  Installing devicons for ranger ..."
  git clone https://github.com/alexanderjeurissen/ranger_devicons ~/.config/ranger/plugins/ranger_devicons
fi
