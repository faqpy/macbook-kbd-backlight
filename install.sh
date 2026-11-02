#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVICE="macsmc-led"

echo "MacBook Keyboard Backlight Installer"

if [ ! -d "/sys/class/leds/$DEVICE" ]; then
    echo "Device '$DEVICE' was not found under /sys/class/leds/."
    echo "Available LED devices:"
    ls /sys/class/leds/ || true
    echo ""
    read -p "Do you want to continue anyway? [y/N] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✓ Found device: /sys/class/leds/$DEVICE"
fi

if ! command -v brightnessctl &>/dev/null; then
    echo "'brightnessctl' is not installed."
    echo "Please install it with your package manager (e.g., 'sudo pacman -S brightnessctl' or 'sudo apt install brightnessctl')."
    exit 1
else
    echo "✓ Found brightnessctl"
fi

echo "Testing keyboard backlight..."
brightnessctl --device="$DEVICE" set 50% -q || true
echo "✓ Backlight set to 50%"

echo ""
read -p "Install 'backlight.sh' to ~/.local/bin/macbook-backlight? [Y/n] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
    mkdir -p "$HOME/.local/bin"
    cp "$DIR/backlight.sh" "$HOME/.local/bin/macbook-backlight"
    chmod +x "$HOME/.local/bin/macbook-backlight"
    echo "✓ Installed CLI tool: macbook-backlight"
fi

I3_CONFIG="$HOME/.config/i3/config"
if [ -f "$I3_CONFIG" ]; then
    if grep -q "macsmc-led" "$I3_CONFIG"; then
        echo "✓ i3 config already contains macsmc-led keybindings."
    else
        echo ""
        read -p "Append keybindings to $I3_CONFIG? [Y/n] " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            echo "" >> "$I3_CONFIG"
            cat "$DIR/i3-backlight.conf" >> "$I3_CONFIG"
            echo "✓ Added keybindings to $I3_CONFIG"
            if command -v i3-msg &>/dev/null; then
                i3-msg reload || true
                echo "✓ Reloaded i3 configuration"
            fi
        fi
    fi
fi

echo ""
read -p "Install udev rule to persist brightness across reboots (requires sudo)? [y/N] " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo cp "$DIR/macsmc-backlight.rules" /etc/udev/rules.d/
    sudo udevadm control --reload-rules && sudo udevadm trigger
    echo "✓ Installed /etc/udev/rules.d/macsmc-backlight.rules"
fi

echo ""
echo "Setup completed successfully!"
