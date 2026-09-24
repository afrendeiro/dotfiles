# gvfs sftp password prompts — gnome-keyring overrides SSH_AUTH_SOCK

Status: **fixed** (2026-09-24) via `IdentityAgent` in `~/.ssh/config`.

## Symptom

Every nautilus mount of `sftp://hilde.int.cemm.at/` or `sftp://login/` (hpc)
popped an "Authentication Required — Enter passphrase for secure key" dialog,
then a password prompt, even though shell `ssh hilde` / `ssh hpc` were fully
passwordless (systemd ssh-agent holds the key, loaded at login by
`load-ssh-key.sh` + the `ssh-add.desktop` autostart).

## Diagnosis

- gvfs's sftp backend does NOT use libssh: it spawns the real `ssh` binary
  (`SSH_PROGRAM`) and drives it through a PTY, translating ssh prompts into
  GTK dialogs.
- Before spawning, `setup_ssh_environment()` in
  `daemon/gvfsbackendsftp.c` calls gnome-keyring's `GetEnvironment` and
  **overwrites `SSH_AUTH_SOCK` with `/run/user/1000/keyring/ssh`**
  (`g_setenv(..., TRUE)`).
- gnome-keyring runs WITHOUT its ssh component here
  (`--components="pkcs11,secrets"` — see the systemd user unit), so that
  socket does not exist. The spawned ssh finds no agent, falls back to
  `IdentityFile ~/.ssh/id_rsa` (passphrase-encrypted) and asks for the key
  passphrase → the nautilus dialog.
- Trigger: gnome-keyring was installed 2026-08-21. Before that, gvfs's
  `GetEnvironment` call failed (no `org.gnome.keyring` bus name) and the
  spawned ssh inherited the session's real `SSH_AUTH_SOCK` (the systemd
  agent) → passwordless.
- Shell ssh was never affected: fish sets
  `SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket`, not the keyring path.

## Fix

Added to each of the `hilde`, `hilde.int.cemm.at`, `login`, `hpc` blocks in
`~/.ssh/config` (local-only file, never committed):

```
IdentityAgent /run/user/1000/ssh-agent.socket
```

`IdentityAgent` overrides the `SSH_AUTH_SOCK` environment variable, so the
ssh spawned by gvfs lands on the systemd agent where the key is already
loaded. Path is UID-hardcoded (single-user machine; ssh_config can't expand
`$XDG_RUNTIME_DIR`).

Verified: `gio mount sftp://hilde.int.cemm.at/` and `gio mount
sftp://login/` mount with no prompt; nautilus bookmarks remount cleanly.

## Alternatives considered

- Tick "Remember password" in the gvfs passphrase dialog (stores the key
  passphrase in gnome-keyring): fragile — depends on the login keyring
  auto-unlocking via the greetd PAM stack.
- Remove the passphrase from `id_rsa` (`ssh-keygen -p`): works everywhere
  but leaves the private key unencrypted at rest — rejected.
- Symlink `/run/user/1000/keyring/ssh` → the real agent socket via
  `user-tmpfiles.d`: works but fragile (ordering vs the keyring daemon).

## If it regresses

Re-check when gnome-keyring's ssh component is ever enabled (the keyring
socket would become real but EMPTY — same prompt, different reason), or if
gvfs changes its `setup_ssh_environment()` behavior (e.g. honoring
`SSH_AUTH_SOCK` when already set).
