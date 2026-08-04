#!/usr/bin/bash
#
# Script: install-applauncher.sh
# Description: Installs AppImageLauncher via its PPA.
#

set -euo pipefail

# add-apt-repository handles fetching/trusting the signing key itself,
# so this doesn't need the old manual apt-key + raw deb-line dance.
sudo add-apt-repository -y ppa:appimagelauncher-team/stable

sudo apt update
sudo apt install -y appimagelauncher

