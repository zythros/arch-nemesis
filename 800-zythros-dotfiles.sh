#!/bin/bash
#set -e
##################################################################################################################################
# Author    : zythros
# Purpose   : Apply personal dotfiles, install suckless tools, and rebuild chadwm
##################################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
##################################################################################################################################
#tput setaf 0 = black
#tput setaf 1 = red
#tput setaf 2 = green
#tput setaf 3 = yellow
#tput setaf 4 = dark blue
#tput setaf 5 = purple
#tput setaf 6 = cyan
#tput setaf 7 = gray
#tput setaf 8 = light blue
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
echo "################### Installing zythros personal dotfiles"
echo "########################################################################"
tput sgr0
echo

# Remove picom-git (conflicts with picom or not needed)
if pacman -Qi picom-git &>/dev/null; then
    tput setaf 3
    echo "Removing picom-git..."
    tput sgr0
    sudo pacman -Rns --noconfirm picom-git
fi

# Remove system dmenu (we'll use zythros fork)
if [ -f /usr/bin/dmenu ]; then
    tput setaf 3
    echo "Removing system dmenu (will be replaced with zythros fork)..."
    tput sgr0
    sudo rm -f /usr/bin/dmenu /usr/bin/dmenu_run /usr/bin/dmenu_path
fi

# Copy .config files from zythros-personal
if [ -d "$installed_dir/zythros-personal/.config" ]; then
    cp -rv "$installed_dir/zythros-personal/.config/"* "$HOME/.config/"
    tput setaf 2
    echo "Copied zythros-personal .config files to ~/.config/"
    tput sgr0
fi

# Set up wallpaper system (calls separate script)
if [ -f "$installed_dir/810-wallpaper-setup.sh" ]; then
    bash "$installed_dir/810-wallpaper-setup.sh"
fi

##################################################################################################################################
# Install dmenu (zythros fork with center, grid, border patches)
##################################################################################################################################

echo
tput setaf 3
echo "########################################################################"
echo "################### Installing dmenu (zythros fork)"
echo "########################################################################"
tput sgr0
echo

DMENU_DIR="$HOME/.config/arco-chadwm/dmenu"
DMENU_REPO="https://github.com/zythros/dmenu.git"

if [ ! -d "$DMENU_DIR" ]; then
    git clone "$DMENU_REPO" "$DMENU_DIR"
fi

cd "$DMENU_DIR"
sudo make clean install

tput setaf 2
echo "dmenu installed from zythros fork"
tput sgr0

##################################################################################################################################
# Install slstatus (zythros fork)
##################################################################################################################################

echo
tput setaf 3
echo "########################################################################"
echo "################### Installing slstatus (zythros fork)"
echo "########################################################################"
tput sgr0
echo

SLSTATUS_DIR="$HOME/.config/arco-chadwm/slstatus"
SLSTATUS_REPO="https://github.com/zythros/slstatus.git"

if [ ! -d "$SLSTATUS_DIR" ]; then
    git clone "$SLSTATUS_REPO" "$SLSTATUS_DIR"
fi

cd "$SLSTATUS_DIR"
sudo make clean install

tput setaf 2
echo "slstatus installed from zythros fork"
tput sgr0

##################################################################################################################################
# Rebuild chadwm with personal config
##################################################################################################################################

if [ -f "$HOME/.config/arco-chadwm/chadwm/config.def.h" ]; then
    echo
    tput setaf 3
    echo "########################################################################"
    echo "################### Rebuilding chadwm with personal config"
    echo "########################################################################"
    tput sgr0
    echo

    cd "$HOME/.config/arco-chadwm/chadwm"

    # Delete config.h to force regeneration from our config.def.h
    # (make clean does NOT remove config.h, so we must do it manually)
    rm -f config.h

    sudo make clean install

    tput setaf 2
    echo "Chadwm rebuilt successfully"
    tput sgr0
fi

##################################################################################################################################
# Summary
##################################################################################################################################

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
echo
echo "Installed components:"
echo "  - chadwm (personal config with dwm-rev1 style tags)"
echo "  - dmenu (zythros fork: center, grid, border patches)"
echo "  - slstatus (zythros fork)"
echo "  - wallpaper.sh (MOD+w / MOD+Shift+w)"
echo "  - sxhkd keybinds"
echo "  - alacritty config (fish shell)"
echo
echo "Key bindings:"
echo "  MOD + d         : dmenu"
echo "  MOD + Space     : Show keybinds"
echo "  MOD + s         : Screenshot (flameshot)"
echo "  MOD + w         : Next wallpaper"
echo "  MOD + Shift + w : Previous wallpaper"
echo "  MOD + Return    : Alacritty (fish)"
echo
tput sgr0
echo
