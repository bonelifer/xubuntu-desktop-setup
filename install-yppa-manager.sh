#!/usr/bin/bash
#
# Script: install-yppa-manager.sh
# Description: Installs Y-PPA-Manager by adding its apt repository and then installing the package.
#
# Note: the original webupd8team PPA this package shipped from has been
# defunct for years (add-apt-repository against it 404s), so this uses the
# still-live ubuntubudgie.net mirror instead of also trying the dead one.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

codename="$(detect_codename)"

echo "deb https://ppa.ubuntubudgie.net/webupd8/y-ppa-manager/ubuntu $codename main" \
    | sudo tee /etc/apt/sources.list.d/y-ppa-manager-ppa.list >/dev/null
echo "deb-src https://ppa.ubuntubudgie.net/webupd8/y-ppa-manager/ubuntu $codename main" \
    | sudo tee -a /etc/apt/sources.list.d/y-ppa-manager-ppa.list >/dev/null

sudo apt update
sudo apt install -y y-ppa-manager
