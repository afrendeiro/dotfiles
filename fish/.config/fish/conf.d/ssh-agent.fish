# SSH agent: socket-activated systemd user service (persists for the session).
set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"

# GUI passphrase prompt (zenity) when a graphical session is available.
if command -q zenity; and test -n "$WAYLAND_DISPLAY$DISPLAY"
    set -gx SSH_ASKPASS "$HOME/.local/bin/ssh-askpass"
    set -gx SSH_ASKPASS_REQUIRE prefer
end

# Unlock the SSH key once per session: the first interactive shell that finds
# the agent empty loads the key. After that `ssh-add -l` succeeds and no more
# prompts appear. If you cancel, the next shell simply prompts again.
if status is-interactive
    and test -n "$XDG_RUNTIME_DIR"
    and test -f "$HOME/.ssh/id_rsa"
    and not ssh-add -l >/dev/null 2>&1
    ssh-add "$HOME/.ssh/id_rsa" >/dev/null 2>&1
end
