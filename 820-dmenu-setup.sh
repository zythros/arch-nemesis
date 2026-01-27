#!/bin/bash
#set -e
##################################################################################################################################
# Author    : zythros
# Purpose   : Install/replace dmenu with zythros fork (can be run standalone)
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
echo "################### Setting up dmenu (zythros fork)"
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

# Check for libXinerama (required for dmenu)
if ! pacman -Qi libxinerama &>/dev/null; then
    tput setaf 3
    echo "Installing libxinerama (required for dmenu)..."
    tput sgr0
    sudo pacman -S --noconfirm --needed libxinerama
fi

##################################################################################################################################
# Remove system dmenu if present
##################################################################################################################################

SYSTEM_DMENU_REMOVED=false

# Check for pacman-installed dmenu
if pacman -Qi dmenu &>/dev/null; then
    tput setaf 3
    echo "Removing pacman-installed dmenu..."
    tput sgr0
    sudo pacman -Rns --noconfirm dmenu
    SYSTEM_DMENU_REMOVED=true
fi

# Check for leftover dmenu binaries in /usr/bin (from previous installs)
if [ -f /usr/bin/dmenu ]; then
    tput setaf 3
    echo "Removing system dmenu at /usr/bin/dmenu..."
    tput sgr0
    sudo rm -f /usr/bin/dmenu /usr/bin/dmenu_run /usr/bin/dmenu_path /usr/bin/stest
    SYSTEM_DMENU_REMOVED=true
fi

if [ "$SYSTEM_DMENU_REMOVED" = true ]; then
    tput setaf 2
    echo "System dmenu removed successfully"
    tput sgr0
fi

##################################################################################################################################
# Clone or update dmenu repository
##################################################################################################################################

DMENU_DIR="$HOME/.config/arco-chadwm/dmenu"
DMENU_REPO="https://github.com/zythros/dmenu.git"

if [ -d "$DMENU_DIR/.git" ]; then
    # Already a git repo - pull latest
    tput setaf 3
    echo "Updating dmenu repository..."
    tput sgr0
    cd "$DMENU_DIR"
    git pull
elif [ -d "$DMENU_DIR" ]; then
    # Directory exists but not a git repo - backup and clone
    tput setaf 3
    echo "Backing up existing dmenu directory and cloning repository..."
    tput sgr0
    mv "$DMENU_DIR" "${DMENU_DIR}.backup.$(date +%s)"
    git clone "$DMENU_REPO" "$DMENU_DIR"
else
    # Fresh install - clone
    tput setaf 3
    echo "Cloning dmenu repository..."
    tput sgr0
    mkdir -p "$(dirname "$DMENU_DIR")"
    git clone "$DMENU_REPO" "$DMENU_DIR"
fi

##################################################################################################################################
# Build and install dmenu
##################################################################################################################################

tput setaf 3
echo "Building and installing dmenu..."
tput sgr0

cd "$DMENU_DIR"
sudo make clean install

if [ $? -eq 0 ]; then
    tput setaf 2
    echo "dmenu built and installed successfully"
    tput sgr0
else
    tput setaf 1
    echo "ERROR: dmenu build failed!"
    tput sgr0
    exit 1
fi

##################################################################################################################################
# Configure sxhkd keybind for dmenu
##################################################################################################################################

SXHKDRC="$HOME/.config/arco-chadwm/sxhkd/sxhkdrc"
DMENU_CMD="dmenu_run -c -l 8 -fn 'JetBrains Mono NerdFont:size=12:style=Bold' -nb '#0a0a0a' -nf '#cdd6f4' -sb '#99f6e4' -sf '#0a0a0a'"

if [ -f "$SXHKDRC" ]; then
    tput setaf 3
    echo "Configuring sxhkd keybind for dmenu..."
    tput sgr0

    # Backup sxhkdrc
    cp "$SXHKDRC" "${SXHKDRC}.bak.$(date +%s)"

    # Check if super + d binding exists
    if grep -q "^super + d$" "$SXHKDRC"; then
        # Replace the command line after "super + d"
        # Use awk to find "super + d" and replace the next non-comment, non-empty line
        awk -v cmd="$DMENU_CMD" '
        /^super \+ d$/ {
            print
            found = 1
            next
        }
        found && /^[[:space:]]+[^#]/ {
            print "    " cmd
            found = 0
            next
        }
        { print }
        ' "$SXHKDRC" > "${SXHKDRC}.tmp" && mv "${SXHKDRC}.tmp" "$SXHKDRC"

        tput setaf 2
        echo "Updated existing super + d binding"
        tput sgr0
    else
        # Add new binding at end of file
        cat >> "$SXHKDRC" << EOF

#dmenu (zythros fork - centered, grid, border patches)
super + d
    $DMENU_CMD
EOF
        tput setaf 2
        echo "Added new super + d binding"
        tput sgr0
    fi

    # Reload sxhkd if running
    if pgrep -x sxhkd >/dev/null; then
        pkill -USR1 -x sxhkd
        tput setaf 2
        echo "Reloaded sxhkd"
        tput sgr0
    fi
else
    tput setaf 3
    echo "NOTE: sxhkdrc not found at $SXHKDRC"
    echo "You may need to manually add the dmenu keybind"
    tput sgr0
fi

##################################################################################################################################
# Verify installation
##################################################################################################################################

DMENU_PATH=$(which dmenu 2>/dev/null)
DMENU_VERSION=$(dmenu -v 2>&1 | head -1)

##################################################################################################################################
# Summary
##################################################################################################################################

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
echo
echo "dmenu (zythros fork) installed:"
echo "  - Source: $DMENU_DIR"
echo "  - Binary: $DMENU_PATH"
echo "  - Version: $DMENU_VERSION"
echo
echo "Patches included:"
echo "  - center: dmenu appears centered on screen"
echo "  - grid: display items in a grid layout"
echo "  - border: adds border around dmenu window"
echo
echo "Usage (sxhkd keybind MOD + d):"
echo "  dmenu_run -c -l 8 -fn 'JetBrains Mono NerdFont:size=12:style=Bold' \\"
echo "    -nb '#0a0a0a' -nf '#cdd6f4' -sb '#99f6e4' -sf '#0a0a0a'"
echo
echo "Options:"
echo "  -c     : Center dmenu on screen"
echo "  -l N   : Show N lines (grid mode)"
echo "  -fn    : Font specification"
echo "  -nb/nf : Normal background/foreground"
echo "  -sb/sf : Selected background/foreground"
echo
tput sgr0
