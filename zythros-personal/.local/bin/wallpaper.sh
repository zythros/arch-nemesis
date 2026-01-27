#!/bin/bash
#
# Wallpaper cycler for dwm/chadwm
# Usage: wallpaper.sh [next|prev|restore]
#
# Cycles through wallpapers in order, persists state across reboots.
#

WALLPAPER_DIR="$HOME/.local/share/wallpapers"
STATE_FILE="$HOME/.local/share/wallpaper-state"

# Get sorted list of wallpapers
get_wallpapers() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) | sort
}

# Get current index from state file
get_index() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo 0
    fi
}

# Save index to state file
save_index() {
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$1" > "$STATE_FILE"
}

# Set wallpaper
set_wallpaper() {
    local file="$1"
    if [ -f "$file" ]; then
        feh --bg-fill "$file"
    fi
}

main() {
    local action="${1:-next}"

    # Get wallpaper list as array
    mapfile -t wallpapers < <(get_wallpapers)
    local count=${#wallpapers[@]}

    if [ "$count" -eq 0 ]; then
        echo "No wallpapers found in $WALLPAPER_DIR"
        exit 1
    fi

    local index=$(get_index)

    case "$action" in
        next)
            index=$(( (index + 1) % count ))
            ;;
        prev)
            index=$(( (index - 1 + count) % count ))
            ;;
        restore)
            # Just use current index
            ;;
        *)
            echo "Usage: $0 [next|prev|restore]"
            exit 1
            ;;
    esac

    save_index "$index"
    set_wallpaper "${wallpapers[$index]}"
}

main "$@"
