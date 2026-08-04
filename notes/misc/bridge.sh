#!/bin/bash

# Create the bridge
sudo ip link add br0 type bridge

# Add the physical interface to the bridge
sudo ip link set wlp3s0 master br0

# Assign a static IP address to the bridge
sudo ip address add dev br0 192.168.1.99/24

# Make the configuration persistent
sudo sysctl net.bridge.bridge-nf-call-iptables=0

# Enable and start the network service
sudo systemctl enable --now network
