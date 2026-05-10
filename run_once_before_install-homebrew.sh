#!/bin/sh
[ "$(uname)" = "Darwin" ] || exit 0
command -v brew >/dev/null 2>&1 && exit 0
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
