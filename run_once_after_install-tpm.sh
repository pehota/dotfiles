#!/bin/sh
TPM_DIR="$HOME/.config/tmux/plugins/tpm"
[ -d "$TPM_DIR" ] && exit 0
git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
