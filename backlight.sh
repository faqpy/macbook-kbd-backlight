#!/usr/bin/env bash
# backlight.sh — Control MacBook keyboard backlight via brightnessctl
# Usage: ./backlight.sh [up|down|set <value>|get|on|off|toggle]

set -euo pipefail

DEVICE="macsmc-led"
STEP="10%"
DEFAULT_BRIGHTNESS="50%"

# Check if device exists
if ! brightnessctl --device="$DEVICE" info &>/dev/null; then
    echo "Error: Device '$DEVICE' not found."
    echo "Available LED devices:"
    brightnessctl -c leds --list 2>/dev/null || brightnessctl --list
    exit 1
fi

get_brightness() {
    brightnessctl --device="$DEVICE" get
}

get_max() {
    brightnessctl --device="$DEVICE" max
}

get_percent() {
    local current max
    current=$(get_brightness)
    max=$(get_max)
    echo $(( current * 100 / max ))
}

case "${1:-get}" in
    up|increase|+)
        brightnessctl --device="$DEVICE" set +"$STEP" -q
        echo "Keyboard backlight: $(get_percent)%"
        ;;
    down|decrease|-)
        brightnessctl --device="$DEVICE" set "$STEP"- -q
        echo "Keyboard backlight: $(get_percent)%"
        ;;
    set)
        if [ -z "${2:-}" ]; then
            echo "Usage: $0 set <value|percentage>"
            echo "Examples: $0 set 128  |  $0 set 50%"
            exit 1
        fi
        brightnessctl --device="$DEVICE" set "$2" -q
        echo "Keyboard backlight: $(get_percent)%"
        ;;
    on)
        brightnessctl --device="$DEVICE" set "$DEFAULT_BRIGHTNESS" -q
        echo "Keyboard backlight on: $(get_percent)%"
        ;;
    off)
        brightnessctl --device="$DEVICE" set 0 -q
        echo "Keyboard backlight off"
        ;;
    toggle)
        current=$(get_brightness)
        if [ "$current" -eq 0 ]; then
            brightnessctl --device="$DEVICE" set "$DEFAULT_BRIGHTNESS" -q
            echo "Keyboard backlight on: $(get_percent)%"
        else
            brightnessctl --device="$DEVICE" set 0 -q
            echo "Keyboard backlight off"
        fi
        ;;
    get|status)
        echo "Device: $DEVICE"
        echo "Brightness: $(get_brightness) / $(get_max) ($(get_percent)%)"
        ;;
    *)
        echo "Usage: $0 [up|down|set <value>|get|on|off|toggle]"
        echo ""
        echo "Commands:"
        echo "  up, increase, +    Increase brightness by $STEP"
        echo "  down, decrease, -  Decrease brightness by $STEP"
        echo "  set <value>        Set brightness to a specific value (e.g. 128 or 50%)"
        echo "  on                 Turn on at $DEFAULT_BRIGHTNESS"
        echo "  off                Turn off"
        echo "  toggle             Toggle between off and $DEFAULT_BRIGHTNESS"
        echo "  get, status        Show current brightness"
        exit 1
        ;;
esac
