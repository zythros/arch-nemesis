#!/bin/bash
#set -e
##################################################################################################################################
# Author    : zythros
# Purpose   : Configure Xorg and kernel for dual NVIDIA GPUs
#             Fixes modesetting/glamor crash that prevents SDDM from starting
##################################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
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

echo
tput setaf 2
echo "########################################################################"
echo "################### Setting up NVIDIA Xorg configuration"
echo "########################################################################"
tput sgr0
echo

# Create Xorg config to force nvidia driver on the display GPU
# BusID pins Xorg to the display GPU so the passthrough GPU is ignored.
# Without this, Xorg may assign the second GPU to modesetting, which crashes via glamor_init.
XORG_CONF="/etc/X11/xorg.conf.d/10-nvidia.conf"

# Detect display GPU PCI address and convert to Xorg BusID format (decimal)
PCI_ADDR=$(lspci | grep "GA106" | grep -i "VGA" | awk '{print $1}')
if [ -z "$PCI_ADDR" ]; then
    tput setaf 1
    echo "ERROR: Could not detect display GPU (GA106) PCI address. Aborting xorg conf write."
    tput sgr0
    exit 1
fi
BUS=$(printf "%d" "0x$(echo "$PCI_ADDR" | cut -d: -f1)")
DEV=$(printf "%d" "0x$(echo "$PCI_ADDR" | cut -d: -f2 | cut -d. -f1)")
FN=$(echo "$PCI_ADDR" | cut -d. -f2)
BUS_ID="PCI:${BUS}:${DEV}:${FN}"
echo "Detected display GPU at $PCI_ADDR → Xorg BusID: $BUS_ID"

echo "Writing $XORG_CONF ..."
sudo tee "$XORG_CONF" > /dev/null << EOF
Section "Device"
    Identifier  "Nvidia Card"
    Driver      "nvidia"
    BusID       "$BUS_ID"
    Option      "NoLogo" "true"
EndSection
EOF
tput setaf 2
echo "Written: $XORG_CONF"
tput sgr0

# Write AutoAddGPU flag in a file that loads LAST (99-n > 99-k alphabetically).
# 99-killX.conf also has a ServerFlags section; if Xorg doesn't merge sections across
# files (last-file-wins per-section), that file would silently drop AutoAddGPU.
# Putting this in 99-nvidia-flags.conf guarantees it survives regardless.
FLAGS_CONF="/etc/X11/xorg.conf.d/99-nvidia-flags.conf"
echo "Writing $FLAGS_CONF ..."
sudo tee "$FLAGS_CONF" > /dev/null << EOF
Section "ServerFlags"
    Option "AutoAddGPU" "false"
EndSection
EOF
tput setaf 2
echo "Written: $FLAGS_CONF"
tput sgr0

##################################################################################################################################
# Enable nvidia-drm.modeset=1 kernel parameter (required for nvidia-open-dkms)
##################################################################################################################################

MODESET_PARAM="nvidia-drm.modeset=1"

# Detect bootloader: systemd-boot or GRUB
if sudo test -f "/boot/loader/loader.conf"; then
    tput setaf 3
    echo "Detected systemd-boot — adding $MODESET_PARAM to boot entries..."
    tput sgr0

    for entry in /boot/loader/entries/*.conf; do
        if grep -q "^options" "$entry"; then
            if ! grep -q "$MODESET_PARAM" "$entry"; then
                sudo sed -i "s/^options .*/& $MODESET_PARAM/" "$entry"
                tput setaf 2
                echo "Updated: $entry"
                tput sgr0
            else
                echo "Already present in: $entry"
            fi
        fi
    done

elif [ -f "/etc/default/grub" ]; then
    tput setaf 3
    echo "Detected GRUB — adding $MODESET_PARAM to /etc/default/grub..."
    tput sgr0

    if ! grep -q "$MODESET_PARAM" /etc/default/grub; then
        sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$MODESET_PARAM /" /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg
        tput setaf 2
        echo "GRUB updated and config regenerated."
        tput sgr0
    else
        echo "$MODESET_PARAM already present in /etc/default/grub"
    fi

else
    tput setaf 1
    echo "Could not detect bootloader. Add '$MODESET_PARAM' to your kernel parameters manually."
    tput sgr0
fi

##################################################################################################################################

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
echo
echo "Configured:"
echo "  - /etc/X11/xorg.conf.d/10-nvidia.conf (forces nvidia Xorg driver, BusID pinned to display GPU)"
echo "  - /etc/X11/xorg.conf.d/99-nvidia-flags.conf (AutoAddGPU false — loads after 99-killX.conf to avoid being overridden)"
echo "  - kernel param: $MODESET_PARAM"
echo
echo "Fixes: Xorg modesetting/glamor crash with dual NVIDIA GPUs"
echo "       that prevented SDDM from reaching the login screen."
echo "       AutoAddGPU=false prevents the secondary GPU from being assigned to modesetting"
echo "       via AddGPUScreen, which triggers a glamor_init assertion crash."
echo
tput sgr0
