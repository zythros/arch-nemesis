#!/bin/bash
#set -e
##################################################################################################################################
# Author    : zythros
# Purpose   : Install/update slstatus from zythros fork (can be run standalone)
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

echo
tput setaf 2
echo "########################################################################"
echo "################### Setting up slstatus (zythros fork)"
echo "########################################################################"
tput sgr0
echo

##################################################################################################################################
# Check for build dependencies
##################################################################################################################################

MISSING_DEPS=""
for dep in git make gcc; do
    if ! command -v $dep &>/dev/null; then
        MISSING_DEPS="$MISSING_DEPS $dep"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    tput setaf 3
    echo "Installing build dependencies:$MISSING_DEPS"
    tput sgr0
    sudo pacman -S --noconfirm --needed $MISSING_DEPS
fi

# Check for libX11 (required for slstatus)
if ! pacman -Qi libx11 &>/dev/null; then
    tput setaf 3
    echo "Installing libx11 (required for slstatus)..."
    tput sgr0
    sudo pacman -S --noconfirm --needed libx11
fi

##################################################################################################################################
# Remove system slstatus if present
##################################################################################################################################

if pacman -Qi slstatus &>/dev/null; then
    tput setaf 3
    echo "Removing pacman-installed slstatus..."
    tput sgr0
    sudo pacman -Rns --noconfirm slstatus
fi

##################################################################################################################################
# Clone or update slstatus repository
##################################################################################################################################

SLSTATUS_DIR="$HOME/.config/arco-chadwm/slstatus"
SLSTATUS_REPO="https://github.com/zythros/slstatus.git"

if [ -d "$SLSTATUS_DIR/.git" ]; then
    # Already a git repo - pull latest
    tput setaf 3
    echo "Updating slstatus repository..."
    tput sgr0
    cd "$SLSTATUS_DIR"
    git pull
elif [ -d "$SLSTATUS_DIR" ]; then
    # Directory exists but not a git repo - backup and clone
    tput setaf 3
    echo "Backing up existing slstatus directory and cloning repository..."
    tput sgr0
    mv "$SLSTATUS_DIR" "${SLSTATUS_DIR}.backup.$(date +%s)"
    git clone "$SLSTATUS_REPO" "$SLSTATUS_DIR"
else
    # Fresh install - clone
    tput setaf 3
    echo "Cloning slstatus repository..."
    tput sgr0
    mkdir -p "$(dirname "$SLSTATUS_DIR")"
    git clone "$SLSTATUS_REPO" "$SLSTATUS_DIR"
fi

##################################################################################################################################
# Build and install slstatus
##################################################################################################################################

tput setaf 3
echo "Building and installing slstatus..."
tput sgr0

cd "$SLSTATUS_DIR"
sudo make clean install

if [ $? -eq 0 ]; then
    tput setaf 2
    echo "slstatus built and installed successfully"
    tput sgr0
else
    tput setaf 1
    echo "ERROR: slstatus build failed!"
    tput sgr0
    exit 1
fi

##################################################################################################################################
# Verify installation
##################################################################################################################################

SLSTATUS_PATH=$(which slstatus 2>/dev/null)

##################################################################################################################################
# Summary
##################################################################################################################################

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
echo
echo "slstatus (zythros fork) installed:"
echo "  - Source: $SLSTATUS_DIR"
echo "  - Binary: $SLSTATUS_PATH"
echo
echo "Modules configured:"
echo "  - Volume (pink #ec4899) - uses pactl"
echo "  - CPU (cyan #06b6d4)"
echo "  - RAM (purple #a855f7)"
echo "  - Date/Time (lime #84cc16)"
echo
echo "Update interval: 100ms"
echo
echo "Configuration:"
echo "  Edit $SLSTATUS_DIR/config.h"
echo "  Then rebuild: cd $SLSTATUS_DIR && sudo make clean install"
echo
echo "Note: Requires status2d patch in dwm/chadwm (already present)"
echo
tput sgr0
