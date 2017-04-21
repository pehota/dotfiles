#!/bin/bash

# Sync Homebrew installations between Macs via Dropbox
#

BREW=$(which brew)
DROPBOX_SYNC_FOLDER="Apps/Homebrew"

echo "Updating Homebrew..."
$BREW update

# first get local settings
echo "Reading local settings ..."
rm -f /tmp/brew-sync.*
$BREW tap > /tmp/brew-sync.taps
$BREW list > /tmp/brew-sync.installed
$BREW cask list -1 > /tmp/brew-sync.casks

# then combine it with list in Dropbox
echo "Reading settings from Dropbox ..."
[ -e ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.taps ] && cat ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.taps >> /tmp/brew-sync.taps
[ -e ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.installed ] && cat ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.installed >> /tmp/brew-sync.installed
[ -e ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.casks ] && cat ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.casks >> /tmp/brew-sync.casks

# make the lists unique and sync into Dropbox
echo "Syncing to Dropbox ..."
mkdir -p ~/Dropbox/$DROPBOX_SYNC_FOLDER
cat /tmp/brew-sync.taps | sort | uniq > ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.taps
cat /tmp/brew-sync.installed | sort | uniq > ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.installed
cat /tmp/brew-sync.casks | sort | uniq > ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.casks

# Set taps
echo "Enabling taps ..."
for TAP in `cat ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.taps`; do
	$BREW tap ${TAP} >/dev/null
done

# Install missing Homebrew packages
echo "Install missing packages ..."
for PACKAGE in `cat ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.installed`; do
	$BREW list ${PACKAGE} >/dev/null
	[ "$?" != "0" ] && $BREW install ${PACKAGE}
done

echo "Install missing casks ..."
for CASK in `cat ~/Dropbox/$DROPBOX_SYNC_FOLDER/brew-sync.casks`; do
	$BREW cask list -1 ${CASK} >/dev/null
	[ "$?" != "0" ] && $BREW cask install ${CASK}
done
