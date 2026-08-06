#!/usr/bin/env bash
set -euo pipefail

echo "=== Ubuntu server setup ==="

echo "=== System update ==="
sudo apt-get update
sudo apt-get install -y build-essential
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

echo "=== Creating user directories ==="
mkdir -p ~/{work,scratch,clones,projects}

echo "=== SSH keepalive ==="
if ! grep -q "ServerAliveInterval" /etc/ssh/ssh_config 2>/dev/null; then
    echo "    ServerAliveInterval 120" | sudo tee -a /etc/ssh/ssh_config
    sudo service ssh restart
fi

echo "=== Locale ==="
if ! grep -q "en_US.UTF-8" /etc/environment 2>/dev/null; then
    cat <<'EOF' | sudo tee -a /etc/environment
LANGUAGE=en_US.UTF-8
LC_ALL=en_US.UTF-8
LANG=en_US.UTF-8
LC_TYPE=en_US.UTF-8
EOF
fi

echo "=== CLI tools ==="
sudo apt-get install -y \
    git \
    curl \
    cmake \
    fish \
    tmux \
    bat \
    fd-find \
    fzf \
    btop \
    neovim \
    npm \
    pass \
    just \
    stow \
    lazygit \
    gh \
    screen \
    at \
    hyperfine \
    pandoc \
    jq \
    dnsutils \
    openconnect

echo "=== Docker ==="
sudo apt-get install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

echo "=== Post-install fixes ==="
sudo ln -sf "$(which fdfind)" /usr/local/bin/fd

echo "=== Done ==="
echo "Don't forget to:"
echo "  - Create a regular user (see comments in this script)"
echo "  - Set the hostname"
echo "  - Clone and deploy dotfiles:"
echo "    git clone git@github.com:afrendeiro/dotfiles.git ~/work/dotfiles"
echo "    cd ~/work/dotfiles && stow fish tmux git nvim alacritty kitty ghostty ipython opencode"
echo "  - Clone password store:"
echo "    git clone git@github.com:afrendeiro/pass.git ~/.password-store"
echo "  - Restore machine-specific config:"
echo "    pass show dotfiles/local.fish > ~/.config/fish/conf.d/local.fish"
