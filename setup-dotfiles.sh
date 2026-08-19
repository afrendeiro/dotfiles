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
BASE_MODULES="scripts fish tmux git herdr nvim ghostty ipython opencode nautilus alacritty kitty"

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

echo "=== Done ==="
echo "Open a new shell for aliases to take effect."
echo "Optional: none — all terminal presets (alacritty/kitty) are stowed;"
echo "they depend on noctalia-generated theme files (see top of script)."
