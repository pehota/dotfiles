#!/bin/bash
set -euo pipefail

if command -v fish >/dev/null 2>&1; then
    fish -c 'set -q fish_function_path[1]; or set -e fish_function_path' >/dev/null 2>&1 || true
fi
