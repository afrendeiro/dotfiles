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
    xclip \
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
    gnome-browser-connector \
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

echo "=== LaTeX ==="
sudo pacman -S --noconfirm \
    texlive-latex \
    texlive-latexextra

echo "=== Cross-platform tools ==="
bash "$SCRIPT_DIR/../common/uv.sh"
bash "$SCRIPT_DIR/../common/herdr.sh"
bash "$SCRIPT_DIR/../common/llm.sh"

echo "=== Python tools ==="
uv tool install cookiecutter

echo "=== Done ==="
echo "Next steps:"
echo "  git clone git@github.com:afrendeiro/dotfiles.git ~/work/dotfiles"
echo "  cd ~/work/dotfiles && stow fish tmux git nvim alacritty kitty ghostty ipython opencode"
echo "  git clone git@github.com:afrendeiro/pass.git ~/.password-store"
echo "  pass show dotfiles/local.fish > ~/.config/fish/conf.d/local.fish"
