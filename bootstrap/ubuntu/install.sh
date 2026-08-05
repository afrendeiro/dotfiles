#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Updating system ==="
sudo apt-get update
sudo apt-get upgrade -y

echo "=== Creating user directories ==="
mkdir -p ~/{work,scratch,clones,projects}

echo "=== Build essentials ==="
sudo apt-get install -y build-essential git curl cmake

echo "=== CLI tools ==="
sudo apt-get install -y \
    fish \
    tmux \
    bat \
    fd-find \
    fzf \
    btop \
    kitty \
    alacritty \
    wl-clipboard \
    neovim \
    pass \
    just \
    lazygit \
    gh \
    stow \
    openconnect \
    screen \
    at \
    hyperfine \
    pandoc \
    jq \
    xclip \
    dnsutils \
    texlive-extra-utils \
    poppler-utils

echo "=== GUI applications ==="
if [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
    sudo apt-get install -y \
        inkscape \
        gimp \
        keepassxc \
        libreoffice \
        hunspell-en-us \
        thunderbird

    # Brave browser
    if ! command -v brave-browser &>/dev/null; then
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
            https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
            | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        sudo apt-get update
        sudo apt-get install -y brave-browser
    fi

    # Signal Desktop
    if ! command -v signal-desktop &>/dev/null; then
        wget -O- https://updates.signal.org/desktop/apt/keys.asc \
            | gpg --dearmor \
            | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
        echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' \
            | sudo tee /etc/apt/sources.list.d/signal-xenial.list
        sudo apt-get update
        sudo apt-get install -y signal-desktop
    fi
else
    echo "No display detected, skipping GUI applications"
fi

echo "=== Fonts ==="
sudo apt-get install -y \
    fonts-roboto \
    fonts-hack \
    fonts-lato
# MS fonts (requires multiverse)
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | sudo debconf-set-selections
sudo apt-get install -y ttf-mscorefonts-installer 2>/dev/null || echo "Skipping MS fonts (multiverse may be missing)"

echo "=== LaTeX ==="
sudo apt-get install -y \
    texlive-latex-base \
    texlive-latex-extra

echo "=== Cross-platform tools ==="
bash "$SCRIPT_DIR/../common/uv.sh"
bash "$SCRIPT_DIR/../common/herdr.sh"
bash "$SCRIPT_DIR/../common/llm.sh"

echo "=== Post-install fixes ==="
sudo ln -sf "$(which fdfind)" /usr/local/bin/fd

echo "=== Python tools ==="
uv tool install cookiecutter

echo "=== Done ==="
echo "Next steps:"
echo "  git clone git@github.com:afrendeiro/dotfiles.git ~/work/dotfiles"
echo "  cd ~/work/dotfiles && stow fish tmux git nvim alacritty kitty ghostty ipython opencode"
echo "  git clone git@github.com:afrendeiro/pass.git ~/.password-store"
echo "  pass show dotfiles/local.fish > ~/.config/fish/conf.d/local.fish"
