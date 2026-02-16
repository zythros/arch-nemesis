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
sudo systemctl enable spice-vdagentd.service
sudo systemctl start spice-vdagentd.service 2>/dev/null

# qemu-guest-agent: host communication channel
sudo systemctl enable qemu-guest-agent.service
sudo systemctl start qemu-guest-agent.service 2>/dev/null

##################################################################################################################################
# 3. Ensure spice-vdagent starts in X session
##################################################################################################################################

echo
echo "Configuring spice-vdagent autostart..."

# spice-vdagent (the user-space client) needs to run in the X session.
# It's typically started via /etc/xdg/autostart/spice-vdagent.desktop
# which the package provides. Verify it exists:
if [ -f /etc/xdg/autostart/spice-vdagent.desktop ]; then
    echo "  XDG autostart entry found (will start on next login)"
else
    # If missing, add it to run.sh as fallback
    RUN_SH="$HOME/.config/arco-chadwm/scripts/run.sh"
    if [ -f "$RUN_SH" ]; then
        if ! grep -q "spice-vdagent" "$RUN_SH"; then
            echo "  Adding spice-vdagent to run.sh..."
            # Add before the status bar section
            sed -i '/bar\.sh/i # Start spice-vdagent for VM clipboard sharing\nspice-vdagent &\n' "$RUN_SH"
            echo "  Added spice-vdagent to run.sh"
        else
            echo "  spice-vdagent already in run.sh"
        fi
    else
        tput setaf 3
        echo "  Warning: No XDG autostart and no run.sh found"
        echo "  You may need to start spice-vdagent manually or add it to your session startup"
        tput sgr0
    fi
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
