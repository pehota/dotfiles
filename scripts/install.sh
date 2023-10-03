#!/usr/bin/env bash

SCRIPTS_FOLDER=$(dirname "$0")

source "$SCRIPTS_FOLDER/utils.sh"

checkRuntime

bootstrap

source "$SCRIPTS_FOLDER/install-utils.sh"

source "$SCRIPTS_FOLDER/install-packages.sh"

echo "Done"
