#!/usr/bin/bash
#
# Script: install-tweaks.sh
# Description: Installs system tweaks for a ThinkPad laptop -- disables
# GNOME screensaver lock, adjusts TLP settings, modifies the fstrim timer,
# and configures touchpad behavior.
#

set -uo pipefail

# Set Nano as the default editor for crontab
sudo update-alternatives --set editor /usr/bin/nano

# Disable GNOME screensaver lock
gsettings set org.gnome.desktop.screensaver lock-enabled false

# Remove false-positive internal errors
sudo sed -i 's/enabled=1/enabled=0/g' /etc/default/apport

# Disable and purge Apport
sudo systemctl disable apport.service
sudo apt purge -y apport

## Turn off swap file
# https://www.cyberciti.biz/faq/linux-check-swap-usage-command/
# https://docs.rackspace.com/support/how-to/create-remove-swap-file-in-ubuntu/
sudo swapoff -a
sudo rm -f /swapfile
## Turn swap partition on via Gnome Disk Utility Manually
sudo sysctl vm.swappiness=100

# Check if the swap partition exists. /dev/sda2 is a block device, not a
# regular file, so this must test with -b (the original -f test was always
# false and silently skipped this block).
if [ -b "/dev/sda2" ]; then
  # Enable the swap partition.
  sudo mkswap /dev/sda2

  # Add the swap partition to the fstab file, unless it's already there
  # (re-running this script would otherwise add a duplicate mount entry
  # every time). Run backup-fstab.sh yourself beforehand if you want a
  # safety copy of fstab before this edit.
  if ! grep -q "^/dev/sda2 " /etc/fstab; then
    echo "/dev/sda2 none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
  fi
fi

# Check if laptop, install tlp and powertop
if [ -d "/proc/acpi/button/lid" ]; then
    sudo apt install --install-suggests -y tlp powertop
    sudo sed -i "s/CPU_BOOST_ON_BAT=1/CPU_BOOST_ON_BAT=0/" /etc/default/tlp
    sudo systemctl restart tlp
fi

# Change fstrim timer from weekly to hourly
sudo sed -i 's/OnCalendar=weekly/OnCalendar=hourly/' /usr/lib/systemd/system/fstrim.timer

# Modify fstrim service to execute with -av option
sudo sed -i 's/ExecStart=\/sbin\/fstrim/ExecStart=\/sbin\/fstrim -av/' /usr/lib/systemd/system/fstrim.service

# Reload systemd daemon to apply changes
sudo systemctl daemon-reload

# Restart fstrim timer to apply hourly schedule
sudo systemctl restart fstrim.timer

# Set gsettings to disable touchpad when an external mouse is connected
gsettings set org.gnome.desktop.peripherals.touchpad send-events disabled-on-external-mouse

# Additional tweaks for ThinkPad
# Configure TrackPoint sensitivity (adjust values as needed)
#xinput --set-prop "TPPS/2 IBM TrackPoint" "libinput Accel Speed" 0.5

# Configure touchpad sensitivity (adjust values as needed)
#xinput --set-prop "SynPS/2 Synaptics TouchPad" "libinput Accel Speed" 0.5


