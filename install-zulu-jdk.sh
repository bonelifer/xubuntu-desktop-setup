#!/usr/bin/bash

#
# Script: install-zulu-jdk.sh
# Description: Install Zulu JDK on Ubuntu.
#

set -euo pipefail

# Update package list
sudo apt update

# The zulu-repo package configures Azul's apt repository and signing key
# itself, so there's no separate apt-key step needed.
zulu_repo_deb="$(mktemp --suffix=.deb)"
curl -fsSL -o "$zulu_repo_deb" https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-2_all.deb
sudo apt install -y "$zulu_repo_deb"
rm -f "$zulu_repo_deb"

# Install Zulu JDK 25 (current LTS)
sudo apt update
sudo apt install -y zulu25-jdk

# Set Zulu as the default Java interpreter
sudo update-alternatives --set java /usr/lib/jvm/zulu25/bin/java
