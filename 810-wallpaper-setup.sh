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
# Clone or update wallpaper repository
##################################################################################################################################

WALLPAPER_DIR="$HOME/.local/share/wallpapers"
WALLPAPER_REPO="https://github.com/zythros/wallpaper.git"

if [ -d "$WALLPAPER_DIR/.git" ]; then
    # Already a git repo - pull latest
    tput setaf 3
    echo "Updating wallpaper repository..."
    tput sgr0
    cd "$WALLPAPER_DIR"
    git pull
elif [ -d "$WALLPAPER_DIR" ] && [ "$(ls -A "$WALLPAPER_DIR" 2>/dev/null)" ]; then
    # Directory exists with files but not a git repo - backup and clone
    tput setaf 3
    echo "Backing up existing wallpapers and cloning repository..."
    tput sgr0
    mv "$WALLPAPER_DIR" "${WALLPAPER_DIR}.backup.$(date +%s)"
    git clone "$WALLPAPER_REPO" "$WALLPAPER_DIR"
else
    # Fresh install - clone
    tput setaf 3
    echo "Cloning wallpaper repository..."
    tput sgr0
    mkdir -p "$(dirname "$WALLPAPER_DIR")"
    git clone "$WALLPAPER_REPO" "$WALLPAPER_DIR"
fi

tput setaf 2
echo "Wallpapers installed at $WALLPAPER_DIR"
tput sgr0

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
