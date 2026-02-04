#!/bin/bash
##################################################################################################################################
# Author    : zythros
# Purpose   : Configure SDDM theme background and settings
##################################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
##################################################################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="/usr/share/sddm/themes/arcolinux-simplicity"
SOURCE_DIR="$SCRIPT_DIR/zythros-personal/sddm-theme"

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
echo "################### Configuring SDDM theme"
echo "########################################################################"
tput sgr0
echo

# Check that SDDM is installed
if ! command -v sddm &>/dev/null; then
    tput setaf 3
    echo "SDDM is not installed - skipping theme configuration"
    tput sgr0
    exit 0
fi

# Check that the theme is installed
if [ ! -d "$THEME_DIR" ]; then
    tput setaf 3
    echo "SDDM theme not found at $THEME_DIR"
    echo "Install it with: sudo pacman -S edu-sddm-simplicity-git"
    tput sgr0
    exit 0
fi

# Check that source files exist
if [ ! -f "$SOURCE_DIR/theme.conf" ]; then
    tput setaf 1
    echo "Source theme.conf not found at $SOURCE_DIR/theme.conf"
    tput sgr0
    exit 1
fi

# Copy theme.conf
sudo cp "$SOURCE_DIR/theme.conf" "$THEME_DIR/theme.conf"
tput setaf 2
echo "Copied theme.conf to $THEME_DIR/"
tput sgr0

# Copy background image(s)
if [ -d "$SOURCE_DIR/images" ]; then
    sudo mkdir -p "$THEME_DIR/images"
    sudo cp "$SOURCE_DIR/images/"* "$THEME_DIR/images/"
    tput setaf 2
    echo "Copied background image(s) to $THEME_DIR/images/"
    tput sgr0
fi

##################################################################################################################################

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
echo
echo "SDDM theme configured:"
echo "  Theme dir : $THEME_DIR"
echo "  Background: $(grep '^background=' "$THEME_DIR/theme.conf" | cut -d= -f2)"
echo
tput sgr0
