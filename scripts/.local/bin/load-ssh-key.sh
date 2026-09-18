#!/bin/sh
# Load the default SSH key into the agent once per session, with a zenity
# passphrase prompt. Invoked by the XDG autostart entry (hyprland module:
# ssh-add.desktop) so GUI apps can use key-based SSH auth (e.g. gvfs/Nautilus
# sftp) before any terminal has been opened. Interactive fish shells do the
# same via fish/.config/fish/conf.d/ssh-agent.fish.
set -eu

[ -n "${SSH_AUTH_SOCK:-}" ] || exit 0
[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ] || exit 0
[ -f "$HOME/.ssh/id_rsa" ] || exit 0

# ssh-add -l exits 0 when the agent already holds an identity -> nothing to do.
ssh-add -l >/dev/null 2>&1 && exit 0

export SSH_ASKPASS="${SSH_ASKPASS:-$HOME/.local/bin/ssh-askpass}"
export SSH_ASKPASS_REQUIRE=force
exec ssh-add "$HOME/.ssh/id_rsa"
