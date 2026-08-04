#!/usr/bin/bash
#
# Script: install-vboxmanage-nopasswd.sh
# Description: Grant the sudo group passwordless sudo for /usr/bin/vboxmanage,
# so VirtualBox VMs can be managed without a sudo password prompt.
#
# This was previously a silent side effect of install-virtual-machines.sh --
# split out here so granting passwordless sudo for anything requires an
# explicit --with-vboxmanage-nopasswd opt-in, same as
# install-add-sudoers-no-password.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

echo '%sudo ALL=(ALL) NOPASSWD: /usr/bin/vboxmanage' | sudo tee /etc/sudoers.d/virtualbox >/dev/null
log "Granted passwordless sudo for /usr/bin/vboxmanage to the sudo group."
