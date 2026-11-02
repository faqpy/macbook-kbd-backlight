# macbook-kbd-backlight
Fix keyboard backlight on MacBooks running Linux with i3wm, Sway, or any standalone window manager.

![MacBook Air](https://img.shields.io/badge/MacBook-Air%207%2C2-333?logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-Arch%20%2F%20CachyOS-1793D1?logo=archlinux&logoColor=white)
![i3wm](https://img.shields.io/badge/WM-i3wm-4C566A?logo=i3&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## The Problem
On MacBooks running Linux, the **keyboard backlight does not work out of the box** in standalone window managers like i3 or Sway. The brightness keys (`F5`/`F6`) do nothing, and the backlight remains completely off after every boot.

### Why this happens:
1. **Non-Standard Device Name**: The Apple SMC kernel driver exposes the keyboard backlight as `macsmc-led` under `/sys/class/leds/macsmc-led/`, rather than standard generic names like `kbd_backlight`.
2. **Missing Keybindings**: Unlike full desktop environments (GNOME/KDE), window managers like i3wm have no default keybindings configured to target `macsmc-led`.
3. **No Auto-Restore by Default**: `systemd-backlight` only watches devices matching `*kbd_backlight*` by default. As a result, `macsmc-led` is ignored and resets to brightness `0` on every reboot.



---

## Method A: Automated Setup
Clone the repository and run the interactive installer:

```bash
git clone https://github.com/faqpy/macbook-kbd-backlight.git
cd macbook-kbd-backlight
chmod +x install.sh
./install.sh
```

The script will verify your hardware, test brightness levels, configure your `~/.config/i3/config`, and optionally install the udev rule for persistent brightness.

---

## Method B: Manual Fix
You can apply the entire fix manually by:

### Step 1: Install `brightnessctl`
Make sure `brightnessctl` is installed on your distro:

```bash
# Arch Linux / CachyOS / Manjaro
sudo pacman -S brightnessctl

# Debian / Ubuntu / Linux Mint
sudo apt install brightnessctl

# Fedora
sudo dnf install brightnessctl
```

### Step 2: Verify Your LED Device Name
Check that your MacBook's keyboard LED interface exists:

```bash
ls -l /sys/class/leds/ | grep -iE 'smc|kbd|mac'
```
You should see `macsmc-led` (or `smc::kbd_backlight` on some older models).

Test controlling it directly from your terminal:
```bash
# Set brightness to 50%
brightnessctl --device='macsmc-led' set 50%

# Dim to 10%
brightnessctl --device='macsmc-led' set 10%

# Turn off
brightnessctl --device='macsmc-led' set 0
```

> **Note**: If your device name is different (e.g. `smc::kbd_backlight`), substitute `macsmc-led` with your device name in the commands below.

---

### Step 3: Add Keybindings to i3wm (or Sway)
Open your window manager config file:
```bash
nano ~/.config/i3/config
# (Or ~/.config/sway/config if using Sway)
```

Append the following lines:

```i3config
# MacBook Keyboard Backlight Controls (F5 / F6)
bindsym XF86KbdBrightnessUp exec --no-startup-id brightnessctl --device='macsmc-led' set +10%
bindsym XF86KbdBrightnessDown exec --no-startup-id brightnessctl --device='macsmc-led' set 10%-

# Fallback bindings (Mod + F5 / Mod + F6)
bindsym $mod+F6 exec --no-startup-id brightnessctl --device='macsmc-led' set +10%
bindsym $mod+F5 exec --no-startup-id brightnessctl --device='macsmc-led' set 10%-

# Turn backlight on to 50% automatically upon login
exec --no-startup-id brightnessctl --device='macsmc-led' set 50%
```

Reload your i3 configuration immediately:
```bash
i3-msg reload
# (Or swaymsg reload for Sway)
```

---

## Keybindings Reference
| Keybinding | Action |
|---|---|
| `F6` (`XF86KbdBrightnessUp`) | Increase keyboard brightness by 10% |
| `F5` (`XF86KbdBrightnessDown`) | Decrease keyboard brightness by 10% |
| `Mod + F6` | Fallback: Increase brightness by 10% |
| `Mod + F5` | Fallback: Decrease brightness by 10% |

---

## Troubleshooting
<details>
<summary><b>1. brightnessctl returns "Device not found"</b></summary>

Check your available LED devices:
```bash
ls -la /sys/class/leds/
brightnessctl --list
```
If your MacBook uses `smc::kbd_backlight` instead of `macsmc-led`, replace `--device='macsmc-led'` with `--device='smc::kbd_backlight'` in your configuration.
</details>

<details>
<summary><b>2. Permission denied when running brightnessctl without sudo</b></summary>

Verify that your user belongs to the `video` or `input` group:
```bash
sudo usermod -aG video $USER
```
Log out and log back in for group membership changes to take effect.
</details>

<details>
<summary><b>3. F5 / F6 keys are treated as standard function keys</b></summary>

Check your `hid_apple` kernel module parameter:
```bash
cat /sys/module/hid_apple/parameters/fnmode
```
- `1`: Media keys by default (F1-F12 require pressing `Fn`)
- `2`: Standard F1-F12 keys by default (Media functions require pressing `Fn`)
- `3`: Auto (default)

If pressing `F5`/`F6` doesn't change brightness, either press `Fn + F5` / `Fn + F6`, or use the fallback keybindings: **`$mod + F5`** and **`$mod + F6`**.
</details>

---

## License
Distributed under the [MIT License](LICENSE).
