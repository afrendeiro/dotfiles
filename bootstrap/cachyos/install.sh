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
    signal-desktop

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

echo "=== Neovim ==="
git clone https://github.com/LazyVim/starter ~/.config/nvim

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

echo "=== Done ==="
echo "Next steps:"
echo "  git clone git@github.com:afrendeiro/dotfiles.git ~/work/dotfiles"
echo "  cd ~/work/dotfiles && stow fish tmux git nvim alacritty kitty ghostty ipython opencode"
echo "  On GNOME machines: stow gnome && ~/.config/gnome/load.sh"
echo "  On Hyprland machines: stow hyprland"
echo "  git clone git@github.com:afrendeiro/pass.git ~/.password-store"
echo "  pass show dotfiles/local.fish > ~/.config/fish/conf.d/local.fish"
