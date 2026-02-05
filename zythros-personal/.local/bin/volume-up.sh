#!/bin/bash
# Raise volume by 10%, cap at 100%
current=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oE "[0-9]+%" | head -1 | tr -d "%")
if [ "$current" -lt 100 ]; then
    new=$((current + 10))
    [ $new -gt 100 ] && new=100
    pactl set-sink-volume @DEFAULT_SINK@ ${new}%
fi
