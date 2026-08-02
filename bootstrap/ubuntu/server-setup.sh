#!/usr/bin/env bash
set -euo pipefail

echo "=== Ubuntu server setup ==="

echo "=== System update ==="
sudo apt-get update
sudo apt-get install -y build-essential
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

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
    tmux \
    bat \
    fd-find \
    fzf \
    btop \
    neovim \
    pass \
    just \
    stow \
    lazygit \
    gh \
    screen \
    at \
    hyperfine \
    pandoc

echo "=== Done ==="
echo "Don't forget to:"
echo "  - Create a regular user (see comments in this script)"
echo "  - Set the hostname"
echo "  - Clone and deploy dotfiles"
