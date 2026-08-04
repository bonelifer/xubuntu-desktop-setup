#!/usr/bin/bash
#
# Script: install-docker.sh
# Description: Install Docker-ce on Ubuntu 22.04
# Reference: https://docs.docker.com/engine/install/linux-postinstall/
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Remove old Docker packages, if present (apt exits 0 even when none are installed).
sudo apt remove -y docker docker-engine docker.io containerd runc || true

# Install prerequisites
sudo apt install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package index
sudo apt update

# Install Docker
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Start Docker service
sudo service docker start

# Create docker group if not exists
sudo groupadd -f docker

# Add current user to docker group
sudo usermod -aG docker "$USER"

# Enable Docker service to start on boot
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

log "Docker installed. The 'docker' group membership won't take effect in this" \
    "shell until you log out and back in (or run 'newgrp docker')."
log "Verify with: docker run hello-world"

