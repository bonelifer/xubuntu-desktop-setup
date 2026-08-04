#!/usr/bin/bash
#
# Script: install-trashy.sh
# Description: Fully automates building and installing the trashy project
# via Git on Ubuntu. Checks for autotools, clones the repository, builds the
# project, and installs it, using a temporary directory that's cleaned up
# afterward.
#

set -euo pipefail

# Step 1: Ensure autotools are installed
echo "Checking if autotools are installed..."
if ! command -v autoreconf &> /dev/null || ! command -v automake &> /dev/null; then
    echo "Autotools not found. Installing..."
    sudo apt update
    sudo apt install -y autotools-dev automake
fi
echo "Autotools are installed."

# Step 2: Create a temporary directory for Git clone
tmp_dir=$(mktemp -d)
echo "Created temporary directory: $tmp_dir"

# Step 3: Clone the repository into the temporary directory
echo "Cloning the trashy repository into the temporary directory..."
git clone https://gitlab.com/trashy/trashy.git "$tmp_dir"
echo "Repository cloned successfully."

# Step 4: Navigate into the cloned directory
cd "$tmp_dir" || exit 1

# Step 5: Run autoreconf
echo "Running autoreconf..."
autoreconf --install
echo "Autoreconf completed successfully."

# Step 6: Run automake
echo "Running automake..."
automake
echo "Automake completed successfully."

# Step 7: Run configure
echo "Running configure..."
./configure
echo "Configure completed successfully."

# Step 8: Run make
echo "Running make..."
make
echo "Make completed successfully."

# Step 9: Install the application
echo "Installing the application..."
sudo make install
echo "Installation completed successfully."

# Step 10: Clean up - remove the temporary directory
echo "Cleaning up..."
cd "$HOME" || exit 1
rm -rf "$tmp_dir"
echo "Temporary directory removed."

echo "Process completed."

