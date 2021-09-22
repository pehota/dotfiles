#!/usr/bin/env bash
set -e

echo "Adding webcam drivers"

pamac install bcwc-pcie-git
