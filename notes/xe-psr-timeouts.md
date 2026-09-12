# xe: "Timed out waiting for PSR Idle for re-enable" at boot/shutdown (PTL)

Status: **baseline captured 2026-09-12** — benign (no visible symptoms, journal
noise only), boot/shutdown-scoped. Panel Replay is active despite
`xe.enable_psr=0`. Compare after 7.2.5; if unchanged, comment on the upstream
xe tickets (see below).

## Symptom

`journalctl -k` shows repeated

```
xe 0000:00:02.0: [drm] *ERROR* Timed out waiting for PSR Idle for re-enable
```

only around display modeset boundaries, never during normal use. No DSB poll
errors, no screen corruption, no flicker/ghosting — i.e. **not** the xe
#8564/#8556 corruption variants.

## Baseline (per boot)

| Boot | Kernel | Timeouts | When |
|---|---|---|---|
| −2 (Sep 9 11:31 → Sep 11 22:49) | 7.2.x-cachyos (journal start rotated, exact version unknown) | 172 | 9 at boot, 9 at +2 min, **154 at shutdown** |
| −1 (Sep 11 22:50 → Sep 12 14:52) | 7.2.4-3-cachyos | 56 | 18 at boot, **38 at shutdown** (14:52:32–44, reboot 14:52:40) |
| 0 (Sep 12 14:53 →) | vanilla 7.2.4-arch1-2 | 10 | 6 at greetd start (14:53:12), 4 at greeter-compositor modeset (14:53:31–32) |

- All are the `for re-enable` variant; 0× `Timed out waiting PSR idle state`,
  0× `DSB … poll error`.
- One `CPU pipe A FIFO underrun` at kernel display init (vanilla boot 0 only).
- Boot bursts coincide with `noctalia-greeter-compositor` starting and logging
  `Buffer is poisoned` / `connector eDP-1|DP-1: Failed to import buffer for
  scan-out` on both connectors.
- **No suspend/resume correlation**: boot −2 had ~8 s2idle cycles, boot −1 a
  14.5 h s2idle sleep — zero timeouts on resume.

## Key finding: `xe.enable_psr=0` does not disable Panel Replay

Root-only debugfs capture (`pkexec`), 2026-09-12, vanilla 7.2.4:

```
/sys/module/xe/parameters/enable_psr             = 0
/sys/module/xe/parameters/enable_panel_replay    = -1   (auto)
/sys/module/xe/parameters/psr_safest_params      = Y
/sys/module/xe/parameters/enable_psr2_sel_fetch  = Y

/sys/kernel/debug/dri/0000:00:02.0/eDP-1/i915_psr_status:
  Sink support: PSR = yes (Early Transport), Panel Replay = yes,
                Panel Replay Selective Update = yes, Panel Replay DSC = selective update
  PSR mode: Panel Replay Selective Update enabled (Early Transport)
  Source PSR/PanelReplay ctl: enabled [0x40000000]
  PSR2_CTL: 0x08000000
  Source PSR/PanelReplay status: SLEEP [0x30200011]
  PSR2 selective fetch: enabled
  Sink PANEL-REPLAY status: 0x2 [active, display from RFB]
```

So the panel's self-refresh is **Panel Replay**, which `xe.enable_psr=0` does not
touch — the `for re-enable` timeout path still runs. `xe.enable_panel_replay=0`
is the untested knob that should actually turn it off.

## Context

- Laptop: XPS 14 DA14260, BIOS 1.8.2; panel **SHP 5571** (Sharp), 1920x1200
  eDP-1; external DP-1 3840x2160@60. VRR off on both (`hyprctl monitors`).
- Cmdline: `quiet nowatchdog xe.enable_psr=0 xe.psr_safest_params=1 …`
  (kernel taints: "Setting dangerous option enable_psr").
- `enable_dsb = Y` (default) — no DSB errors on this machine.

## Upstream refs (Intel DRM tracker, gitlab.freedesktop.org/drm/xe/kernel)

- **#8564** "PTL: PSR and VRR can cause screen corruption" — same SoC family
  (Ultra X7 358H / Arc B390); lists the same timeout string plus DSB/FIFO errors;
  reporter says `xe.enable_psr=0` mitigates but does not clear everything.
- **#8556** "PTL: VSync locks to 30 FPS … root cause: DSB poll errors".
- **#9196** PTL eDP-2 PHY refclk failure.
- Our variant (timeout-only, no DSB, no corruption, boot/shutdown only) is a
  useful datapoint for either ticket.

## Re-collection commands (run after 7.2.5)

```sh
# per-boot PSR stats: kernel, counts, window
for b in $(journalctl --list-boots --no-pager | awk '{print $1}'); do
  J=$(journalctl -b "$b" -k --no-pager 2>/dev/null)
  printf 'boot %s | %s | timeouts=%s (re-enable=%s, idle-state=%s) | DSB=%s FIFO=%s | %s .. %s\n' \
    "$b" "$(echo "$J" | grep -m1 -oE 'Linux version [^ ]+')" \
    "$(echo "$J" | grep -c 'Timed out waiting')" \
    "$(echo "$J" | grep -c 'for PSR Idle for re-enable')" \
    "$(echo "$J" | grep -c 'Timed out waiting PSR idle state')" \
    "$(echo "$J" | grep -c 'DSB.*poll error')" \
    "$(echo "$J" | grep -c 'FIFO underrun')" \
    "$(echo "$J" | grep 'Timed out waiting' | head -1 | cut -c1-15)" \
    "$(echo "$J" | grep 'Timed out waiting' | tail -1 | cut -c1-15)"
done

# when do they fire? (per-minute histogram)
journalctl -b <IDX> -k --no-pager | grep 'Timed out waiting' | cut -c1-16 | uniq -c

# effective PSR/Panel Replay state (root)
pkexec sh -c 'cat /sys/module/xe/parameters/enable_psr /sys/module/xe/parameters/enable_panel_replay; \
  cat /sys/kernel/debug/dri/0000:00:02.0/eDP-1/i915_psr_status'
```

## Next steps

1. **7.2.5**: rerun the commands above on the first boot with the same cmdline —
   comparison stays clean only if `xe.enable_panel_replay` is left at auto.
2. If the bursts persist: comment on xe **#8564** (or #8556) with this baseline —
   XPS 14 DA14260, timeout-only variant, boot/shutdown scoped, and the Panel
   Replay observation.
3. Then (optional workaround test): boot once with
   `xe.enable_panel_replay=0` added to `/etc/default/limine` and see if the
   timeouts disappear. Only after the 7.2.5 comparison, to keep the baseline
   valid.
