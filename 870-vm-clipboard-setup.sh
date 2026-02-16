#!/bin/bash
##################################################################################################################################
# Author    : zythros
# Purpose   : Set up host-VM clipboard sharing (copy/paste) via SPICE
#             Installs spice-vdagent and qemu-guest-agent for QEMU/KVM VMs
##################################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
##################################################################################################################################

installed_dir=$(dirname $(readlink -f $(basename `pwd`)))

##################################################################################################################################

if [ "$DEBUG" = true ]; then
    echo
    echo "------------------------------------------------------------"
    echo "Running $(basename $0)"
    echo "------------------------------------------------------------"
    echo
    read -n 1 -s -r -p "Debug mode is on. Press any key to continue..."
    echo
fi

##################################################################################################################################
# Check if running inside a VM
##################################################################################################################################

# Detect virtualization - skip on bare metal
VIRT_TYPE=$(systemd-detect-virt 2>/dev/null)

if [ "$VIRT_TYPE" = "none" ] || [ -z "$VIRT_TYPE" ]; then
    tput setaf 3
    echo "Not running inside a VM - skipping clipboard setup"
    tput sgr0
    exit 0
fi

echo
tput setaf 2
echo "########################################################################"
echo "################### Setting up VM clipboard sharing"
echo "########################################################################"
tput sgr0
echo
echo "Detected virtualization: $VIRT_TYPE"

##################################################################################################################################
# 1. Install packages
##################################################################################################################################

echo
echo "Installing VM guest packages..."

# spice-vdagent: clipboard sharing, auto-resize, drag-and-drop
sudo pacman -S --noconfirm --needed spice-vdagent

# qemu-guest-agent: host-guest communication (shutdown, freeze, info queries)
sudo pacman -S --noconfirm --needed qemu-guest-agent

# xclip/xsel: clipboard utilities (useful for scripting clipboard access)
sudo pacman -S --noconfirm --needed xclip

##################################################################################################################################
# 2. Enable services
##################################################################################################################################

echo
echo "Enabling services..."

# spice-vdagentd: system daemon that manages the SPICE agent connection
# These units are "static" (activated via socket), so normal enable may not work.
# Use --force to create symlinks for static units, and enable the socket as well.
sudo systemctl enable spice-vdagentd.service --force 2>/dev/null
sudo systemctl enable spice-vdagentd.socket --force 2>/dev/null
sudo systemctl start spice-vdagentd.socket 2>/dev/null
sudo systemctl start spice-vdagentd.service 2>/dev/null

# qemu-guest-agent: host communication channel
sudo systemctl enable qemu-guest-agent.service --force 2>/dev/null
sudo systemctl start qemu-guest-agent.service 2>/dev/null

##################################################################################################################################
# 3. Ensure spice-vdagent starts in X session
##################################################################################################################################

echo
echo "Configuring spice-vdagent autostart..."

# --- XDG autostart (for XFCE and other desktop environments) ---
if [ -f /etc/xdg/autostart/spice-vdagent.desktop ]; then
    echo "  XDG autostart entry found (XFCE/DEs will start on next login)"
else
    echo "  XDG autostart entry missing - creating it..."
    sudo tee /etc/xdg/autostart/spice-vdagent.desktop > /dev/null << 'DESKTOP'
[Desktop Entry]
Name=Spice vdagent
Comment=Agent for Spice guests
Exec=/usr/bin/spice-vdagent
Terminal=false
Type=Application
NoDisplay=true
DESKTOP
    echo "  Created /etc/xdg/autostart/spice-vdagent.desktop"
fi

# --- run.sh injection (for chadwm which doesn't read XDG autostart) ---
RUNSH="$HOME/.config/arco-chadwm/scripts/run.sh"
if [ -f "$RUNSH" ]; then
    if grep -q "spice-vdagent" "$RUNSH"; then
        echo "  run.sh already has spice-vdagent (chadwm covered)"
    else
        echo "  Adding spice-vdagent to run.sh (for chadwm)..."
        cp "$RUNSH" "$RUNSH.bak.$(date +%s)"
        # Insert before picom line
        sed -i '/^picom -b/i # VM clipboard sharing (only runs if spice-vdagent is installed)\ncommand -v spice-vdagent \&>\/dev\/null \&\& run "spice-vdagent"\n' "$RUNSH"
        echo "  Added to $RUNSH"
    fi
else
    echo "  chadwm run.sh not found (will be covered if chadwm is installed later)"
fi

# If we're in a graphical session, start it now
if [ -n "$DISPLAY" ]; then
    if ! pgrep -x spice-vdagent &>/dev/null; then
        echo "  Starting spice-vdagent..."
        spice-vdagent &
        sleep 1
    else
        echo "  spice-vdagent already running"
    fi
fi

##################################################################################################################################
# 4. Summary
##################################################################################################################################

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
echo
echo "VM clipboard sharing:"
echo "  - spice-vdagent (clipboard sync, auto-resize)"
echo "  - qemu-guest-agent (host-guest communication)"
echo "  - xclip (clipboard utilities)"
echo
echo "Services enabled:"
echo "  - spice-vdagentd.service (system daemon)"
echo "  - qemu-guest-agent.service (host communication)"
echo
echo "Copy/paste between host and VM should work after next login."
echo "If not working now, log out and back in (or reboot)."
echo
tput sgr0
echo
