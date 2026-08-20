#!/usr/bin/env bash
set -euo pipefail

# Install teams-tui-go (terminal UI for Microsoft Teams) from prebuilt
# GitHub releases. No Go toolchain needed on the machine.

VERSION=v1.2.6
URL="https://github.com/nospor/teams-tui-go/releases/download/${VERSION}/teams-tui-go-${VERSION}-linux-amd64.tar.gz"
BIN=$HOME/.local/bin/teams-tui-go

if [ -x "$BIN" ]; then
    echo "teams-tui-go already installed"
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -fsSL "$URL" | tar -xz -C "$TMP"
install -Dm755 "$TMP/teams-tui-go" "$BIN"
echo "Installed teams-tui-go ${VERSION} to $BIN"
