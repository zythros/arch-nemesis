#!/bin/bash
#set -e
##################################################################################################################################
# Author    : zythros
# Purpose   : Configure Xorg and kernel for NVIDIA GPUs (RTX 3060 LHR + RTX 3090)
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

# Create Xorg config to force nvidia driver
# Without this, Xorg defaults to modesetting which crashes via glamor_init with NVIDIA hardware
XORG_CONF="/etc/X11/xorg.conf.d/10-nvidia.conf"
echo "Writing $XORG_CONF ..."
sudo tee "$XORG_CONF" > /dev/null << 'EOF'
Section "Device"
    Identifier  "Nvidia Card"
    Driver      "nvidia"
    Option      "NoLogo" "true"
EndSection
EOF
tput setaf 2
echo "Written: $XORG_CONF"
tput sgr0

##################################################################################################################################
# Enable nvidia-drm.modeset=1 kernel parameter (required for nvidia-open-dkms)
##################################################################################################################################

MODESET_PARAM="nvidia-drm.modeset=1"

# Detect bootloader: systemd-boot or GRUB
if [ -d "/boot/loader/entries" ] && ls /boot/loader/entries/*.conf &>/dev/null; then
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
echo "  - /etc/X11/xorg.conf.d/10-nvidia.conf (forces nvidia Xorg driver)"
echo "  - kernel param: $MODESET_PARAM"
echo
echo "Fixes: Xorg modesetting/glamor crash with NVIDIA hardware (RTX 3060 LHR + RTX 3090)"
echo "       that prevented SDDM from reaching the login screen."
echo
tput sgr0
