#!/bin/bash

# Create the bridge configuration file
echo "<network>
  <name>br0</name>
  <forward mode="bridge"/>
  <bridge name="br0"/>
</network>" > br0.xml

# Start the bridge
virsh net-define br0.xml
virsh net-start br0

# Enable the bridge to start automatically at system boot
virsh net-autostart br0

# Configure VMs to use the bridge network
for vm in $(virsh list --all | tail -n +3 | awk '{print }'); do
  virsh edit $vm
  echo "<interface type="bridge">
    <source bridge="br0"/>
  </interface>" >> $vm
  virsh start $vm
done
