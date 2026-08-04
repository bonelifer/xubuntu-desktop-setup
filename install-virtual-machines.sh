#!/usr/bin/bash
#
# Script: install-virtual-machines.sh
# Description: Installs and configures virtualization tools such as QEMU,
# libvirt, and VirtualBox on a Linux system.
#

set -euo pipefail

# BEGIN QEMU and libvirt installation section
# Install QEMU virtualization suite, including the KVM hypervisor, libvirt daemon, libvirt clients, bridge-utils, virtinst, virt-manager, gnome-boxes, vmstat, virsh, virt-top, qemu-img, virt-clone, and virt-net.
sudo apt install -y qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst virt-manager gnome-boxes vmstat virsh virt-top qemu-img virt-clone virt-net

# Start the libvirt daemon
sudo systemctl start libvirtd

# Enable the libvirt daemon to start automatically at system boot
sudo systemctl enable libvirtd
# END QEMU and libvirt installation section

# BEGIN virtual network bridge configuration
# Define the bridge network configuration
cat <<EOF | sudo tee /etc/libvirt/qemu/networks/br0.xml
<network>
  <name>br0</name>
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network>
EOF

# Start the bridge network
sudo virsh net-define /etc/libvirt/qemu/networks/br0.xml
sudo virsh net-start br0

# Enable the bridge network to start automatically at system boot
sudo virsh net-autostart br0

# Configure VMs to use the bridge network
for vm in $(sudo virsh list --all | awk 'NR > 2 {print $2}'); do
  sudo virsh attach-interface --domain "$vm" --type bridge --source br0 --model virtio --config
  # `virsh start` errors on an already-running VM; that's not a failure worth aborting for.
  sudo virsh start "$vm" || echo "Note: $vm may already be running."
done
# END virtual network bridge configuration

# Install VirtualBox and its components
sudo apt install -y virtualbox virtualbox-ext-pack virtualbox-guest-additions virtualbox-manager virtualbox-dkms virtualbox-headless

# Passwordless sudo for vboxmanage is opt-in -- see install-vboxmanage-nopasswd.sh
# (packages.conf OPTIONAL_MODULES: --with-vboxmanage-nopasswd), not granted here.

# Restart libvirt for changes to take effect
sudo systemctl restart libvirtd

