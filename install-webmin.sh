#!/usr/bin/bash

# Script: install-webmin.sh
# Description: Install Webmin on Ubuntu Linux via the official installer
# script, which configures Webmin's own apt repo/key and installs it.
# This is the sole owner of the Webmin repo/key setup; install-main.sh does
# not duplicate it.

set -euo pipefail

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

cd "$temp_dir"
curl -fsSL -O https://software.virtualmin.com/gpl/scripts/install.sh
chmod +x ./install.sh
sudo ./install.sh
