#!/usr/bin/bash
#
# Script: install-starship.sh
# Description: Installs Starship terminal prompt customization for Bash.
#

set -euo pipefail

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install Rust
install_rust() {
    echo "Rust is required to install Starship."
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # rustup/cargo aren't on PATH yet in this shell without this.
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
}

# Function to install Starship
install_starship() {
    # Check if Rust is installed
    if ! command_exists rustup; then
        install_rust
    fi
    
    # Install Starship using Cargo (Rust's package manager)
    echo "Installing Starship..."
    if ! command_exists starship; then
        rustup update
        cargo install starship
    else
        echo "Starship is already installed."
    fi
}

# Function to configure Starship for Bash
configure_starship() {
    local bashrc="$HOME/.bashrc"
    # shellcheck disable=SC2016 # intentionally literal -- this gets written into .bashrc verbatim
    local init_line='eval "$(starship init bash)"'

    if grep -qF "$init_line" "$bashrc" 2>/dev/null; then
        echo "Starship configuration already present in .bashrc."
    else
        echo "$init_line" >> "$bashrc"
        echo "Starship configuration added to .bashrc."
    fi
}

# Main function
main() {
    install_starship
    configure_starship
    echo "Starship installation and configuration completed."
}

# Call the main function
main

