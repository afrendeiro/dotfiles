# Boot optimization — plymouth off + silent session start

Status: **fixed** 2026-08-23 (verified after reboot). Changes live outside the
repo (`/etc`, `/usr/local`); this note is the record.

## What was fixed

1. **CachyOS boot animation removed and boot sped up ~3.8s.** The plymouth
   `cachyos-bootanimation` splash was active via `splash` in the limine kernel
   cmdline. The real cost was `plymouth-quit-wait.service`, which held greetd
   for **3.833s** (plymouthd took ~4s to shut down after `plymouth quit`) —
   it was the first item on `systemd-analyze critical-chain`.
2. **Black screen + terminal text after entering the password removed.** After
   login, `uwsm` printed its startup block ("Selected compositor ID: …",
   "Created dir …", etc.) to tty1, visible on the black screen until
   Hyprland's first frame (see `/dev/vcs1` for the smoking gun).

## Root causes (why the obvious fix didn't work)

- The noctalia greeter **ignores `/etc/greetd/environments`** — it builds the
  session command from the `wayland-sessions` `.desktop` file's `Exec`
  (`hyprland-uwsm.desktop` → `uwsm start -e -D Hyprland hyprland.desktop`) and
  passes `cmd` + `args` to greetd, which spawns it with the VT as stdout.
  A wrapper in `environments` never runs.
- The printed lines are uwsm's own unconditional CLI output
  (`/usr/share/uwsm/modules/uwsm/main.py`, `print_normal` in `uwsm start`) —
  sensible for login-shell launch, a wart under a display manager. No uwsm
  flag exists to quiet it and no upstream issue tracks it (checked
  github.com/Vladimir-csp/uwsm issues). The fix mirrors what
  `noctalia-greeter-session` already does for the greeter: park stdio.

## Changes made

**plymouth disabled** (animation gone, greetd no longer gated):

- `/etc/default/limine` — `KERNEL_CMDLINE[default]+=` now
  `"quiet nowatchdog rw rootflags=subvol=/@ root=UUID=762d3d18-…"` (no
  `splash`; `timeout: 1` untouched).
- `/etc/mkinitcpio.conf` — `plymouth` removed from `HOOKS`.
- `/etc/kernel/cmdline` — synced (previously held a dead `plymouth.enable=0`
  that `/etc/default/limine` overrode anyway).
- `pkexec systemctl mask plymouth-start plymouth-quit plymouth-quit-wait` —
  the masks are what actually kill the 3.8s gate; the units are pulled by
  `multi-user.target` regardless of `splash`.
- Rebuilt via `pkexec mkinitcpio -P` (regenerates both initramfs + limine.conf
  via the limine hook).

**Silent session start** (VT stays black after password):

- `/usr/local/bin/uwsm` — PATH-shadow wrapper (session PATH puts
  `/usr/local/bin` before `/usr/bin`, so greetd's bare `uwsm` lookup hits it):
  `exec /usr/bin/uwsm "$@" >>"${HOME}/.local/share/uwsm-session.log" 2>&1`
- `/usr/local/bin/start-hyprland` — same pattern for the plain "Hyprland"
  session entry (belt-and-suspenders; uwsm-managed is the default).
- The earlier, ineffective attempt was reverted: `/etc/greetd/environments`
  back to `/usr/bin/Hyprland`, `/usr/local/bin/session-hyprland` removed.

## Result

- `systemd-analyze`: userspace **7.487s → 4.543s** (greetd now starts after
  docker/containerd, not plymouth), total ~17s → ~14s (firmware phase varies
  ±0.5s). Kernel/initrd phases were already fast (0.5s / 2.6s).
- Login: black → greeter, and password → black → desktop with **no text**.
  uwsm's output is preserved in `~/.local/share/uwsm-session.log`.

## Backups / revert

- Snapper snapshot **132** "pre-boot-fixes: plymouth removal + greetd session
  wrapper" — has its own limine boot entry (old kernel + initramfs preserved).
- `~/boot-config-backup-20260823/` — copies of every touched /etc file.
- `/boot/limine.conf.pre-change`.
- Revert per piece: remove `/usr/local/bin/uwsm` + `/usr/local/bin/start-hyprland`;
  `pkexec systemctl unmask plymouth-start plymouth-quit plymouth-quit-wait`;
  restore `splash` in `/etc/default/limine` + the hook in `/etc/mkinitcpio.conf`
  and `pkexec mkinitcpio -P`.

## Update resilience

- Wrappers are in `/usr/local/bin` — no pacman package owns those paths; uwsm
  is exec'd by absolute path. Worst case (uwsm relocating its binary) is a
  loud exec failure, not a silent break.
- Masks live in `/etc/systemd/system` (survive updates); `/etc` configs are
  user-owned (pacman drops `.pacnew`, never overwrites).
- The plymouth package stays installed but inert.

## TODO (future agent)

- Snapshot entries in `/boot/limine.conf` still carry `splash` until the next
  snapper event regenerates them (harmless — plymouth is masked and not in the
  initramfs).
- Optional: `pacman -Rns plymouth` to drop the package entirely (kept for now
  in case CachyOS tooling references it).
- If a CachyOS tool ever re-adds `splash` to a regenerated cmdline, only the
  animation returns; the masks still hold.
