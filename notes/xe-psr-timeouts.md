# xe: "Timed out waiting for PSR Idle for re-enable" at boot/shutdown (PTL)

Status: **workaround confirmed 2026-09-30** (`xe.enable_panel_replay=0` → 0
timeouts, one-off boot, not yet permanent); **unresolved upstream (last checked
2026-09-29, on 7.2.8-1)** — mostly
benign journal noise, boot/shutdown-scoped on 7.2.x. Panel Replay is active
despite `xe.enable_psr=0`. 7.3-rc2 changed the variant and added DSB errors +
visible flicker; 7.2.8 adds runtime `PSR idle state` timeouts (likely a
stable revert, see below). No upstream fix targets this panel — expected path
is the `xe.enable_panel_replay=0` workaround and/or a DMI+panel quirk (see
"Upstream status & fix timeline").

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
| Sep 15 23:46 → | 7.2.5-1-cachyos | 8 (boot burst only; shutdown count pending next reboot) | 5 at greetd start (23:46:19–20), 3 at greeter-compositor modeset (23:46:32–33) |
| Sep 28 08:55 → 19:59 | 7.2.7-1-cachyos (probably; version line rotated out) | 253 | 3 at boot, **250 at shutdown/reboot** (19:57–19:59) |
| Sep 28 19:59 → | 7.2.8-1-cachyos | 16 so far: 9× `for re-enable` + **7× `PSR idle state`** | 9 at boot (19:59); idle-state pairs at 21:26, 22:53, 23:08, 23:16 — during normal desktop use; 0 DSB, 0 FIFO; fullscreen RDR2 session 2026-09-29 logged nothing |

- All are the `for re-enable` variant; 0× `Timed out waiting PSR idle state`,
  0× `DSB … poll error`.
- One `CPU pipe A FIFO underrun` at kernel display init (vanilla 7.2.4 boot 0
  and CachyOS 7.2.5-1, both at display init).
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

## RC observation 2026-09-14 — `7.3.0-rc2-3-cachyos-rc`

First boot on the CachyOS RC kernel (same cmdline, `enable_panel_replay` left at
auto). The display-error profile changes:

- PSR timeouts: only **2**, both the `Timed out waiting PSR idle state` variant
  (18:02:58 and 18:03:00, during the RDR2 crash/teardown). **No**
  `for PSR Idle for re-enable` bursts at boot/shutdown anymore.
- **15× `[CRTC:153:pipe A] DSB 0 poll error`** — new on this machine (0 on all
  7.2.x boots): 18:01:02–11 (session start) and 18:02:37–56 (RDR2 fullscreen
  modeset).
- The DSB scanline fix **is present** in the CachyOS `7.3-rc2` source
  (`intel_vrr_safe_window_start(crtc_state) - 1` with the stale-PIPEDSL comment,
  upstream `f7140c7`) — so these DSB errors occur *with* the patch applied and
  VRR off. Relevant nuance for CachyOS #1024, where the missing patch was
  suspected as the DSB-error cause.
- Panel Replay still active despite `enable_psr=0` (`enable_panel_replay=-1`,
  debugfs status `SU_STANDBY` instead of the 7.2.4 `SLEEP`).
- **Visible symptoms on rc**: after the RDR2 launch the screen became unstable —
  flickering and tearing — with no further kernel messages after the last DSB
  error. Not seen on 7.2.x or LTS. This is a **display regression in 7.3-rc2**,
  not benign journal noise; the rc kernel is not safe as a daily driver on this
  machine (reboot to 7.2.4-3/LTS).

## Stable 7.2.5 observation 2026-09-15 — `7.2.5-1-cachyos`

First boot on the stable 7.2.5-1 build (same cmdline, `enable_panel_replay` left
at auto):

- 8 PSR timeouts, all the `for PSR Idle for re-enable` variant, greetd/modeset-
  scoped (23:46:19–33) — same profile as the 7.2.4 baseline; 0× `PSR idle state`,
  0× `DSB … poll error`, 1× FIFO underrun at display init.
- During the RDR2 crash/teardown (23:49–23:50): 0 PSR timeouts, 0 DSB errors —
  the rc2 DSB burst does **not** reproduce on stable 7.2.5.
- Shutdown burst count pending the next reboot.

## Stable 7.2.8 observation 2026-09-29 — `7.2.8-1-cachyos`

- First time the `Timed out waiting PSR idle state` variant (2 s wait on PSR
  disable) shows up on a **stable** kernel, and outside any modeset: 7× during
  ordinary desktop use. Previously rc2-only.
- Likely cause (inference): 7.2.8 reverted "drm/i915/display: Clear
  SEL_FETCH_PLANE_CTL on plane disable" (added in 7.2.5; revert = upstream
  `a26204be587c`) without its replacement, which is queued for 7.2.9.
- 7.2.6/7.2.7 carried no PSR/Panel Replay/DSB changes (7.2.7: cdclk only).

## Workaround test 2026-09-30 — `xe.enable_panel_replay=0` (7.2.8-1)

One-off boot (limine `e` edit) with `xe.enable_panel_replay=0 xe.enable_psr=0
xe.psr_safest_params=1`:

- **0 timeouts** of either variant through greetd + session start (every
  earlier 7.2.x boot: 5–18 by that point), 0 DSB, 0 FIFO underrun.
- debugfs `i915_psr_status`: `PSR mode: disabled` (was `Panel Replay Selective
  Update enabled (Early Transport)`); both params read `0`.
- For comparison, the preceding 7.2.8 boot (Panel Replay on) ended with 181×
  `for re-enable` (172 in the shutdown burst) + 7× `PSR idle state`.
- → Panel Replay is the trigger. Trade-off: with both off the panel has **no
  self-refresh at all** (some battery cost). Still to check: the shutdown
  burst of this boot, and whether dropping `xe.enable_psr=0` (keeping PSR2
  with Panel Replay off) stays clean.

## Upstream status & fix timeline (researched 2026-09-29)

gitlab issue comments need a login; lore/patchwork block scripted access —
status below is from the gitlab API, torvalds mirror, kernel.org ChangeLogs and
stable-queue.

- **Tickets**: xe #8564 / #8556 / #9196 all **open, unassigned** (last activity
  09-09 / 09-09 / 09-28). Newer PTL matches, all open: #9253, #9296, #9385 (DSB
  poll errors/corruption), #8924 (Panel Replay parks in SLEEP with
  `enable_psr2_sel_fetch=0`), #8930 (XPS 13 WCL PR-SU stutter), #9119 (XPS 16:
  DPCD 0x107 advertises AS SDP while PR_ALPM_CTL disables it — patch
  "drm/i915/psr: Clarify AS SDP handling in Panel Replay mode", unmerged).
  omarchy #11016: **same model (DA14260)**, Panel Replay lag on 7.2.3/7.2.4,
  fixed by `xe.enable_panel_replay=0`. CachyOS #1024: `enable_dsb=0` stops DSB
  errors but not the stutter.
- **Existing quirk doesn't cover this unit**: `45c77d4bf8d4` "Disable Panel
  Replay on Dell XPS 14 DA14260 as a quirk" + `1de647abdfda` (both 7.1) match
  the **LGD panel** only; this machine has the **Sharp SHP 5571**, and debugfs
  shows Panel Replay active — consistent with the quirk not matching.
  (Unverified against source locally.)
- **7.2.9** (stable-queue/queue-7.2): "drm/i915/psr: Clear stale sel fetch
  enable bits on sel fetch disable" (mainline `2777ec985227`, closes xe#8739),
  plus `c034e8a46e4c` "drm/i915/vrr: Disable DC balance by default" (Cc stable
  v7.0+; VRR-only). Expected to remove the 7.2.8 runtime timeouts.
- **7.3** (final ~late Oct): DSB safe-window fixes (`f7140c7cef30`,
  `4a68c7516c57`), PTL DC3CO rework, `cd0121502ce6` "Block DC3CO entry during
  active frame". Nothing aimed at the `for re-enable` wait (50 ms wait in the
  PSR work handler) or the `PSR idle state` wait (2 s, on disable). rc2 showed a
  display regression on this machine — retest rc5+ before trusting 7.3.
- **7.4** (~end of Dec, drm-intel-next): `3659b6d90f98` "clear the Panel Replay
  error status register" (wrong DPCD address, no stable tag), AS SDP
  skip-frames series (`8dbe5c47ca42`, `dc0fd724e13a`, `eddf77ff1a23`,
  `9ed39b7d74b4`), `908f1be9c343` "On DPCD init wake the DPRx for eDP". Earliest
  real Panel Replay improvements — generic, not a fix for this panel.
- **Assessment**: a targeted fix in 7.2.y or 7.3 is unlikely; realistic
  paths are the workaround below, a quirk extension (needs a report), or the
  7.4 Panel Replay work.

## Workaround knobs (verified present in 7.2.8 and 7.3-rc4 `modinfo xe`)

- `xe.enable_panel_replay=0` — the confirmed fix for DA14260 (omarchy #11016),
  XPS 16 and WCL; falls back to PSR1/PSR2.
- `xe.enable_psr2_sel_fetch=0` — **avoid**: with Panel Replay still on it can
  freeze the panel (xe #8924).
- `xe.enable_dsb`, `xe.enable_dc` (0–4), `xe.psr_safest_params` — secondary.
- Early Transport has no module param; runtime-only via debugfs
  `i915_edp_psr_debug` (`0x20` = disable ET, `0x40` = disable Panel Replay).

## Context

- Laptop: XPS 14 DA14260, BIOS 1.8.2; panel **SHP 5571** (Sharp), 1920x1200
  eDP-1; external DP-1 3840x2160@60. VRR off on both (`hyprctl monitors`).
- Cmdline: `quiet nowatchdog xe.enable_psr=0 xe.psr_safest_params=1 …`
  (kernel taints: "Setting dangerous option enable_psr").
- `enable_dsb = Y` (default) — no DSB errors on 7.2.x; 15 on 7.3-rc2.

## Upstream refs (Intel DRM tracker, gitlab.freedesktop.org/drm/xe/kernel)

- **#8564** "PTL: PSR and VRR can cause screen corruption" — same SoC family
  (Ultra X7 358H / Arc B390); lists the same timeout string plus DSB/FIFO errors;
  reporter says `xe.enable_psr=0` mitigates but does not clear everything.
- **#8556** "PTL: VSync locks to 30 FPS … root cause: DSB poll errors".
- **#9196** PTL eDP-2 PHY refclk failure.
- Our variant: on 7.2.x timeout-only, no DSB, no corruption, boot/shutdown only;
  on 7.3-rc2 the DSB errors appear *with* the scanline patch present (VRR off) —
  useful datapoint for #8556/#1024.

## Re-collection commands (run on stable 7.2.6 and any future kernel)

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

1. ~~Workaround test~~ done 2026-09-30: `xe.enable_panel_replay=0` → 0
   timeouts (see above). Remaining: count this boot's shutdown burst (next
   boot, `journalctl -b -1 -k`), try one boot WITHOUT `xe.enable_psr=0` (PSR2
   on, Panel Replay off), then make the chosen set permanent in
   `/etc/default/limine` (+ `limine-update`).
2. Optional isolation: runtime `echo 0x20 > …/i915_edp_psr_debug` (ET off only)
   to see whether Early Transport alone triggers the timeouts.
3. **7.2.9** when packaged: re-count — expect the runtime `PSR idle state`
   timeouts to go away (sel-fetch replacement patch).
4. **File a drm/xe issue** for the Sharp SHP 5571 on DA14260: attach EDID/OUI
   + `i915_psr_status`, cite #9119 and omarchy #11016, ask for the DA14260
   Panel Replay quirk (`45c77d4bf8d4`) to cover this panel too.
5. 7.3 final / 7.4-rc1: retest (rc2 flicker regression; 7.4 Panel Replay/AS SDP
   series).
