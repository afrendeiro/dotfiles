# Dock: external display dead after unplug/replug (aquamarine 0.15.0 regression)

Status: **unresolved upstream** (last checked 2026-09-14). Recovery: VT switch
(`SUPER+SHIFT+F10` → `recover-displays.sh`), suspend/resume, or reboot.

## Symptom

Dell WD19S dock on the XPS 14 DA14260 (Panther Lake, `xe`): booting with the
dock attached works, but after unplugging and replugging the dock, USB,
ethernet and power come back while the external monitor (Dell U2720Q, dock DP)
never does. `/sys/class/drm` loses the dynamic MST connectors (DP-5/DP-6) and
they do not reappear; Hyprland only reports eDP-1. The Type-C layer still shows
the DP alt mode as active (`/sys/class/typec/port1-partner/port1-partner.0/`
`active=yes`, SVID `ff01`), so this is not the dock, cable, or monitor.

## Root cause

aquamarine 0.15.0 regression from `core/drm: introduce async commits` (#363,
commit `9d6fed9`): on connector teardown the disable commit is rejected —

```
ERR from aquamarine ]: drm: Cannot commit a disconnected output
drm: DP-6 is not connected, clearing stale crtc 270
```

— so the kernel CRTC stays active. On Intel that holds the Type-C port's link
refcount and the port never re-enters DP-alt mode, making the sink invisible to
the driver on the next plug. Reported on i915, xe and amdgpu (multiple hardware
generations), with the same fix boundary.

## Recovery

- `SUPER+SHIFT+F10` → `~/.local/bin/recover-displays.sh`: switches to another
  VT and back via `pkexec chvt`. fbcon does a full modeset that releases the
  stale CRTC; confirmed working 2026-09-14 (same as manual `Ctrl+Alt+F3`, wait,
  `Ctrl+Alt+F1`). May need one dock replug afterwards.
- `systemctl suspend` + wake also releases the stale pipe; reboot always works.
- Alternative while waiting: downgrade the ABI-matched pre-regression set
  `hyprland 0.56.2-1` + `aquamarine 0.14.0-2` (Arch Linux Archive,
  `archive.archlinux.org`, with their `.sig` files) and `IgnorePkg` both.

## Upstream

- https://github.com/hyprwm/aquamarine/issues/386 — CRTC of a removed connector
  never disabled; re-plugged outputs fail modeset with EINVAL
- https://github.com/hyprwm/aquamarine/issues/403 — USB-C DP-alt connector never
  re-detected after replug (our MST DP-5/DP-6 fingerprint)
- Fix PRs #395, #399, #400 — closed, **not merged** as of 2026-09-14
- https://gitlab.freedesktop.org/drm/i915/kernel/-/issues/16256 and
  https://bugs.kde.org/show_bug.cgi?id=490623 — same defect in KWin

## TODO (future agent)

When aquamarine > 0.15.0 ships with the fix (`pacman -Q aquamarine`): verify the
dock replug works, then remove `recover-displays.sh`, its `SUPER+SHIFT+F10`
bind, the AGENTS.md bullet, and this note's recovery section.
