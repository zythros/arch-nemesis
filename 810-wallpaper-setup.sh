#!/bin/bash
#set -e
##################################################################################################################################
# Author    : zythros
# Purpose   : Set up wallpaper cycling system (can be run standalone)
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
echo "################### Setting up wallpaper system"
echo "########################################################################"
tput sgr0
echo

##################################################################################################################################
# Install feh (required for setting wallpapers)
##################################################################################################################################

if ! command -v feh &>/dev/null; then
    tput setaf 3
    echo "Installing feh (required for wallpaper system)..."
    tput sgr0
    sudo pacman -S --noconfirm --needed feh
fi

##################################################################################################################################
# Copy wallpaper.sh script
##################################################################################################################################

WALLPAPER_SCRIPT="$installed_dir/zythros-personal/.local/bin/wallpaper.sh"
DEST_DIR="$HOME/.local/bin"

mkdir -p "$DEST_DIR"

if [ -f "$WALLPAPER_SCRIPT" ]; then
    cp -v "$WALLPAPER_SCRIPT" "$DEST_DIR/"
    chmod +x "$DEST_DIR/wallpaper.sh"
    tput setaf 2
    echo "Installed wallpaper.sh to $DEST_DIR/"
    tput sgr0
else
    tput setaf 1
    echo "ERROR: wallpaper.sh not found at $WALLPAPER_SCRIPT"
    tput sgr0
    exit 1
fi

##################################################################################################################################
# Create wallpapers directory
##################################################################################################################################

WALLPAPER_DIR="$HOME/.local/share/wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    mkdir -p "$WALLPAPER_DIR"
    tput setaf 2
    echo "Created wallpapers directory at $WALLPAPER_DIR"
    tput sgr0
fi

##################################################################################################################################
# Copy default wallpapers if available
##################################################################################################################################

DEFAULT_WALLPAPERS="$installed_dir/zythros-personal/.local/share/wallpapers"

if [ -d "$DEFAULT_WALLPAPERS" ] && [ "$(ls -A "$DEFAULT_WALLPAPERS" 2>/dev/null)" ]; then
    cp -v "$DEFAULT_WALLPAPERS"/* "$WALLPAPER_DIR/" 2>/dev/null
    tput setaf 2
    echo "Copied default wallpapers to $WALLPAPER_DIR"
    tput sgr0
fi

##################################################################################################################################
# Check PATH
##################################################################################################################################

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    tput setaf 3
    echo "NOTE: ~/.local/bin is not in your PATH"
    echo "Add this to your shell config (~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish):"
    echo ""
    echo "  # Bash/Zsh:"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "  # Fish:"
    echo "  set -gx PATH \$HOME/.local/bin \$PATH"
    tput sgr0
fi

##################################################################################################################################
# Summary
##################################################################################################################################

WALLPAPER_COUNT=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) 2>/dev/null | wc -l)

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
echo
echo "Wallpaper system installed:"
echo "  - Script: ~/.local/bin/wallpaper.sh"
echo "  - Wallpapers: $WALLPAPER_DIR ($WALLPAPER_COUNT images found)"
echo
if [ "$WALLPAPER_COUNT" -eq 0 ]; then
    tput setaf 3
    echo "WARNING: No wallpapers found!"
    echo "Add images to $WALLPAPER_DIR for the system to work."
    echo ""
    echo "Example:"
    echo "  cp ~/Pictures/*.jpg $WALLPAPER_DIR/"
    tput sgr0
    echo
fi
echo "Usage:"
echo "  wallpaper.sh next     - Next wallpaper"
echo "  wallpaper.sh prev     - Previous wallpaper"
echo "  wallpaper.sh restore  - Restore last wallpaper (for startup)"
echo
echo "Keybinds (sxhkd):"
echo "  MOD + w         : Next wallpaper"
echo "  MOD + Shift + w : Previous wallpaper"
echo
tput sgr0
