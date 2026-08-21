#!/usr/bin/env bash
set -euo pipefail

# Apply dotfiles on a fresh machine.
# Stows repo configs over any stock/preset files (CachyOS skel, bootstrap-created
# ~/.gitconfig and LazyVim starter) by adopting then restoring the repo's tracked
# versions. Idempotent: safe to re-run.
# alacritty + kitty are tracked (noctalia theme, opacity 0.6).
# NOTE: their configs `import`/`include` noctalia-generated theme files
# (alacritty/themes/noctalia.toml, kitty/themes/noctalia.conf). Without noctalia
# installed, drop the import/include or use a different theme.

REPO_URL="git@github.com:afrendeiro/dotfiles.git"
REPO_DIR="$HOME/work/dotfiles"
BASE_MODULES="scripts fish tmux git herdr nvim ghostty ipython opencode nautilus alacritty kitty teams-tui-go systemd"

echo "=== Cloning dotfiles ==="
if [ ! -d "$REPO_DIR/.git" ]; then
    git clone "$REPO_URL" "$REPO_DIR"
else
    git -C "$REPO_DIR" pull --ff-only || echo "  WARNING: pull failed (local changes?)"
fi
cd "$REPO_DIR"

echo "=== Stowing core modules ==="
for m in $BASE_MODULES; do
    if stow --adopt "$m"; then
        git restore --source=HEAD -- "$m" 2>/dev/null || true
    else
        echo "  WARNING: failed to stow $m"
    fi
done

echo "=== Cleaning LazyVim starter leftovers (if any) ==="
rm -rf "$HOME/.config/nvim/.git"
rm -f  "$HOME/.config/nvim/LICENSE" \
        "$HOME/.config/nvim/README.md" \
        "$HOME/.config/nvim/lua/plugins/example.lua"

echo "=== Desktop environment extras ==="
case "${XDG_SESSION_DESKTOP:-}${XDG_CURRENT_DESKTOP:-}" in
    *[Hh]yprland*)
        stow hyprland
        echo "Stowed hyprland module"
        ;;
    *[Gg]nome*)
        stow gnome
        bash "$HOME/.config/gnome/load.sh"
        echo "Stowed gnome module and loaded keybindings"
        ;;
    *)
        echo "  Unknown desktop environment, skipping DE-specific modules"
        ;;
esac

echo "=== Password store ==="
if [ ! -d "$HOME/.password-store" ]; then
    git clone git@github.com:afrendeiro/pass.git "$HOME/.password-store" \
        || echo "  WARNING: could not clone password store"
fi
if command -v pass >/dev/null 2>&1 \
        && pass show dotfiles/local.fish >/dev/null 2>&1; then
    pass show dotfiles/local.fish > "$HOME/.config/fish/conf.d/local.fish"
    echo "Restored machine-specific fish config"
fi

echo "=== Camera (IPU7) system setup ==="
# The XPS 14 webcam is an IPU7 + OV08X40 MIPI sensor behind a Synaptics CVS
# bridge. It needs: the out-of-tree intel_cvs driver (built via DKMS), the
# modprobe load order, libcamera configured for the CPU soft ISP (the GPU
# path crashes with libcamera >= 0.7.2 on the ipu7 driver's stride), and a
# udev rule keeping IPU7 runtime-active (suspend/resume driver bug).
# See notes/camera-ipu7.md.
if [ -d "$REPO_DIR/bootstrap/cachyos/udev/rules.d" ]; then
    if sudo install -Dm644 "$REPO_DIR"/bootstrap/cachyos/udev/rules.d/*.rules \
            /etc/udev/rules.d/ && sudo udevadm control --reload-rules; then
        echo "  Installed IPU7 udev rules"
    else
        echo "  WARNING: could not install udev rules (need sudo)"
    fi
fi
if [ -d "$REPO_DIR/bootstrap/cachyos/modprobe.d" ]; then
    if sudo install -Dm644 "$REPO_DIR"/bootstrap/cachyos/modprobe.d/*.conf \
            /etc/modprobe.d/; then
        echo "  Installed modprobe.d configs (ipu7-usbio-order, v4l2loopback)"
    else
        echo "  WARNING: could not install modprobe.d configs (need sudo)"
    fi
fi
if [ -d "$REPO_DIR/bootstrap/cachyos/modules-load.d" ]; then
    sudo install -Dm644 "$REPO_DIR"/bootstrap/cachyos/modules-load.d/*.conf \
            /etc/modules-load.d/ \
        && echo "  Installed modules-load.d (v4l2loopback)"
fi
sudo install -Dm644 "$REPO_DIR/bootstrap/cachyos/libcamera/configuration.yaml" \
        /etc/libcamera/configuration.yaml \
    && echo "  Installed libcamera config (software_isp cpu mode)"
if command -v dkms >/dev/null 2>&1; then
    if [ -d /usr/src/vision-driver-1.0.0 ]; then
        echo "  vision-driver (intel_cvs) already in /usr/src"
    else
        echo "  Cloning intel/vision-drivers for DKMS (intel_cvs)"
        sudo git clone --depth 1 https://github.com/intel/vision-drivers.git \
            /usr/src/vision-driver-1.0.0
        sudo dkms add vision-driver/1.0.0
    fi
    if ! dkms status 2>/dev/null | grep -q "vision-driver/1.0.0: installed"; then
        sudo dkms build vision-driver/1.0.0 && sudo dkms install vision-driver/1.0.0
    fi
    echo "  intel_cvs DKMS module installed (auto-rebuilds on kernel updates)"
fi

echo "=== Enabling camera relay (libcamera -> v4l2loopback) ==="
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user enable --now ipu7-camera-relay.service 2>/dev/null \
    && echo "  ipu7-camera-relay.service running (webcam at /dev/video33)" \
    || echo "  WARNING: could not enable ipu7-camera-relay (login session only; enable manually)"

echo "=== Linking herdr plugin(s) ==="
if command -v herdr >/dev/null 2>&1; then
    if herdr plugin list --json 2>/dev/null | grep -q '"plugin_id":"file-picker"'; then
        echo "  file-picker plugin already linked"
    else
        herdr plugin link "$REPO_DIR/herdr/plugins/file-picker" \
            || echo "  WARNING: could not link file-picker plugin"
    fi
fi

echo "=== Done ==="
echo "Open a new shell for aliases to take effect."
echo "Optional: none — all terminal presets (alacritty/kitty) are stowed;"
echo "they depend on noctalia-generated theme files (see top of script)."
