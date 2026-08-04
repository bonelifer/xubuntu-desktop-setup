#!/usr/bin/bash
#
# Script: install-vcron.sh
# Description: Installs Zeit CRONTAB (vcron).
# Reference: http://daniel.roche.free.fr/vcron/vcronGB.html
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# The rpm just provides the supporting files (docs, tcl libs) and package
# registration via alien/dpkg. files/vcron is a separately hand-patched
# build (enlarged window, old blurry image removed) -- always install that
# over the rpm's own executable, don't fetch vcron-2.3-1.noarch.rpm from
# daniel.roche.free.fr instead.
RPM_FILE="$SCRIPT_DIR/files/vcron-2.3.1-1.x86_64.rpm"
CUSTOM_VCRON="$SCRIPT_DIR/files/vcron"

# Install required packages
sudo apt install -y alien at

# Convert RPM package to DEB using alien and install
sudo alien -i "$RPM_FILE"

# Find wherever alien actually put vcron on PATH, then overwrite it with
# the hand-patched build, so we end up with the customized version
# regardless of where alien installed to.
installed_path="$(which vcron)" || die "vcron not found on PATH after alien install"

sudo cp "$CUSTOM_VCRON" "$installed_path"
sudo chmod 755 "$installed_path"
log "vcron installed to $installed_path"


