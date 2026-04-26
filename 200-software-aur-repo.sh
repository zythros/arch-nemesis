#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common/common.sh"

log_section "Running $(script_name)"

pause_if_debug

##################################################################################################################################
# Author    : Erik Dubois
# Website   : https://www.erikdubois.be
# Youtube   : https://youtube.com/erikdubois
##################################################################################################################################
#
#   DO NOT JUST RUN THIS. EXAMINE AND JUDGE. RUN AT YOUR OWN RISK.
#
#   Purpose:
#   - Install selected software from the AUR.
#   - Keep the AUR logic separate from repo-based package installs.
#
##################################################################################################################################

log_section "Build Opera from AUR"

install_aur_package opera

if ! grep -q "artix" /etc/os-release; then
	result=$(systemd-detect-virt)

	if [ $result = "none" ]; then
		log_section "Installing VirtualBox"
		sh install/install-virtualbox-for-linux.sh
	else
		log_warn "You are on a virtual machine - skipping VirtualBox"
	fi
fi

log_section "Build from install folder"

if ! pacman -Qi mullvad-browser &>/dev/null; then
    yay -S mullvad-browser-bin --noconfirm
else
    echo "Mullvad browser is already installed."
fi

log_subsection "Building pamac-aur"

if ! pacman -Qi libpamac-aur &>/dev/null; then
    yay -S libpamac-aur --noconfirm
else
    echo "libpamac-aur is already installed."
fi

if ! pacman -Qi pamac-aur &>/dev/null; then
    yay -S pamac-aur --noconfirm
else
    echo "pamac-aur is already installed."
fi

log_subsection "$(script_name) done"
