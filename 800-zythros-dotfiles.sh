#!/bin/bash
#set -e
##################################################################################################################################
# Author    : zythros
# Purpose   : Apply personal dotfiles and rebuild chadwm
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

# Copy .config files from zythros-personal
if [ -d "$installed_dir/zythros-personal/.config" ]; then
    cp -rv "$installed_dir/zythros-personal/.config/"* "$HOME/.config/"
    tput setaf 2
    echo "Copied zythros-personal .config files to ~/.config/"
    tput sgr0
fi

# Rebuild chadwm if config was updated
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

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
tput sgr0
echo
