#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Updating system ==="
sudo pacman -Syu --noconfirm

echo "=== Creating user directories ==="
mkdir -p ~/{work,scratch,clones,projects}

echo "=== CLI tools ==="
sudo pacman -S --noconfirm \
    git \
    tmux \
    bat \
    fd \
    fzf \
    dust \
    btop \
    kitty \
    alacritty \
    wl-clipboard \
    neovim \
    npm \
    pass \
    just \
    curl \
    stow \
    lazygit \
    github-cli \
    openconnect \
    screen \
    at \
    hyperfine \
    pandoc \
    base-devel \
    jq \
    bind \
    poppler

echo "=== GUI applications ==="
sudo pacman -S --noconfirm \
    brave-origin-bin \
    inkscape \
    gimp \
    keepassxc \
    opencode \
    libreoffice-fresh \
    hunspell-en_us \
    thunderbird \
    spotify-launcher \
    signal-desktop \
    evince \
    imv \
    celluloid \
    nautilus-python

echo "=== Libraries and utilities ==="
sudo pacman -S --noconfirm \
    libxml2 \
    libxml2-legacy \
    ncompress

echo "=== Fonts ==="
sudo pacman -S --noconfirm \
    ttf-roboto \
    ttf-hack \
    ttf-lato

if ! pacman -Qs ttf-ms-fonts &>/dev/null; then
    git clone https://aur.archlinux.org/ttf-ms-fonts.git /tmp/ttf-ms-fonts
    (cd /tmp/ttf-ms-fonts && makepkg -si --noconfirm)
    rm -rf /tmp/ttf-ms-fonts
fi

echo "=== Docker ==="
sudo pacman -S --noconfirm \
    docker \
    docker-compose \
    docker-buildx
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

echo "=== LaTeX ==="
sudo pacman -S --noconfirm \
    texlive-latex \
    texlive-latexextra

echo "=== Cross-platform tools ==="
bash "$SCRIPT_DIR/../common/uv.sh"
bash "$SCRIPT_DIR/../common/herdr.sh"
bash "$SCRIPT_DIR/../common/vicinae.sh"
bash "$SCRIPT_DIR/../common/llm.sh"
bash "$SCRIPT_DIR/../common/btop.sh"
bash "$SCRIPT_DIR/../common/pyright.sh"

echo "=== Python tools ==="
uv tool install cookiecutter

echo "=== Git globals ==="
git config --global user.name "Andre Rendeiro"
git config --global user.email "afrendeiro@gmail.com"
git config --global init.defaultBranch main

echo "=== Desktop environment extras ==="
case "${XDG_SESSION_DESKTOP:-}${XDG_CURRENT_DESKTOP:-}" in
    *[Hh]yprland*)
        bash "$SCRIPT_DIR/de/hyprland.sh"
        ;;
    *[Gg]nome*)
        bash "$SCRIPT_DIR/de/gnome.sh"
        ;;
    *)
        echo "Unknown desktop environment, skipping DE-specific packages"
        echo "  Run manually: bash $SCRIPT_DIR/de/gnome.sh or de/hyprland.sh"
        ;;
esac

echo "=== Default applications ==="
xdg-mime default org.gnome.Evince.desktop application/pdf
xdg-mime default imv-dir.desktop \
    image/png image/jpeg image/gif image/svg+xml image/webp image/bmp \
    image/tiff image/heif image/avif image/jxl image/qoi image/x-farbfeld
xdg-mime default io.github.celluloid_player.Celluloid.desktop \
    video/mp4 video/mkv video/webm video/x-matroska video/quicktime \
    video/x-msvideo video/mpeg video/x-m4v video/ogg video/3gpp \
    video/x-flv video/mp2t video/avi
xdg-mime default brave-origin.desktop x-scheme-handler/http x-scheme-handler/https
xdg-mime default org.gnome.Nautilus.desktop inode/directory

echo "=== Done ==="
echo "Next steps:"
echo "  bash ~/work/dotfiles/setup-dotfiles.sh   (or clone first: git clone git@github.com:afrendeiro/dotfiles.git ~/work/dotfiles)"
echo "  git clone git@github.com:afrendeiro/pass.git ~/.password-store"
echo "  pass show dotfiles/local.fish > ~/.config/fish/conf.d/local.fish"
