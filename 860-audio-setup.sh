#!/bin/bash
##################################################################################################################################
# Author    : zythros
# Purpose   : Set up PipeWire audio stack and configure sane defaults
#             Works on both VMs and bare metal
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
echo "################### Setting up PipeWire audio"
echo "########################################################################"
tput sgr0
echo

##################################################################################################################################
# 1. Install PipeWire packages
##################################################################################################################################

echo "Installing PipeWire audio stack..."

# Core PipeWire packages
sudo pacman -S --noconfirm --needed pipewire
sudo pacman -S --noconfirm --needed wireplumber
sudo pacman -S --noconfirm --needed pipewire-alsa
sudo pacman -S --noconfirm --needed pipewire-jack
sudo pacman -S --noconfirm --needed pipewire-zeroconf

# 32-bit compatibility (Steam, Wine)
sudo pacman -S --noconfirm --needed lib32-pipewire
sudo pacman -S --noconfirm --needed lib32-pipewire-jack

# ALSA utilities (amixer for setting defaults)
sudo pacman -S --noconfirm --needed alsa-utils

##################################################################################################################################
# 2. Remove PulseAudio and install pipewire-pulse replacement
#    pipewire-pulse conflicts with pulseaudio, so remove PA first
##################################################################################################################################

echo
echo "Migrating from PulseAudio to PipeWire..."

# Stop PulseAudio if currently running (user session)
systemctl --user stop pulseaudio.socket pulseaudio.service 2>/dev/null

# Remove PulseAudio packages (force - pipewire-pulse will replace them)
for pkg in pulseaudio-alsa pulseaudio-bluetooth pulseaudio; do
    if pacman -Qi "$pkg" &>/dev/null; then
        echo "  Removing $pkg..."
        sudo pacman -Rdd --noconfirm "$pkg"
    fi
done

# Remove jack2 if present (conflicts with pipewire-jack)
if pacman -Qi jack2 &>/dev/null; then
    echo "  Removing jack2 (replaced by pipewire-jack)..."
    sudo pacman -Rdd --noconfirm jack2
fi

# Now install pipewire-jack (after jack2 is removed)
sudo pacman -S --noconfirm --needed pipewire-jack
sudo pacman -S --noconfirm --needed lib32-pipewire-jack

# Now install pipewire-pulse (provides pulseaudio API compatibility)
sudo pacman -S --noconfirm --needed pipewire-pulse

##################################################################################################################################
# 3. Enable PipeWire user services, disable PulseAudio
##################################################################################################################################

echo
echo "Configuring systemd user services..."

# Disable PulseAudio socket/service (may already be gone with package removal)
systemctl --user disable pulseaudio.socket 2>/dev/null
systemctl --user disable pulseaudio.service 2>/dev/null

# Enable PipeWire sockets and session manager
systemctl --user enable pipewire.socket
systemctl --user enable pipewire-pulse.socket
systemctl --user enable wireplumber.service

# Start PipeWire now if in a graphical session
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    echo "Starting PipeWire services..."
    systemctl --user start pipewire.socket
    systemctl --user start pipewire-pulse.socket
    systemctl --user start wireplumber.service
    # Give services a moment to initialize
    sleep 2
fi

##################################################################################################################################
# 4. Set sane default volume (unmuted, 75%)
##################################################################################################################################

echo
echo "Setting default volume..."

VOLUME_SET=false

# Method 1: wpctl (WirePlumber / PipeWire native)
if command -v wpctl &>/dev/null; then
    wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null && \
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.75 2>/dev/null && \
    VOLUME_SET=true && echo "  Volume set via wpctl (PipeWire)"
fi

# Method 2: pactl (PulseAudio-compatible - works with pipewire-pulse)
if [ "$VOLUME_SET" = false ] && command -v pactl &>/dev/null; then
    pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null && \
    pactl set-sink-volume @DEFAULT_SINK@ 75% 2>/dev/null && \
    VOLUME_SET=true && echo "  Volume set via pactl"
fi

# Method 3: amixer (ALSA level - works without any audio server)
if [ "$VOLUME_SET" = false ] && command -v amixer &>/dev/null; then
    amixer set Master 75% unmute 2>/dev/null && \
    VOLUME_SET=true && echo "  Volume set via amixer (ALSA)"
fi

if [ "$VOLUME_SET" = false ]; then
    tput setaf 3
    echo "  Warning: Could not set volume (no audio server running)"
    echo "  Volume will use PipeWire defaults on next login"
    tput sgr0
fi

##################################################################################################################################
# 5. Summary
##################################################################################################################################

echo
tput setaf 6
echo "##############################################################"
echo "###################  $(basename $0) done"
echo "##############################################################"
echo
echo "Audio stack:"
echo "  - PipeWire (core audio server)"
echo "  - WirePlumber (session manager)"
echo "  - pipewire-pulse (PulseAudio compatibility)"
echo "  - pipewire-alsa (ALSA compatibility)"
echo "  - pipewire-jack (JACK compatibility)"
echo
echo "PulseAudio removed. All apps using pactl/pavucontrol"
echo "will continue to work via pipewire-pulse."
echo
if [ "$VOLUME_SET" = true ]; then
    echo "Default volume: 75%, unmuted"
else
    echo "Volume will be set on next graphical login"
fi
echo
tput sgr0
echo
