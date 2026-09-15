# [BUG] RDR2 (Steam/Proton) crashes during engine init on Linux 7.2.x–7.3-rc2 (CachyOS + vanilla Arch); works on 6.18 LTS

Status: **upstream regression confirmed, still unfixed in mainline 7.3-rc2 and
stable 7.2.5** — reproduces on vanilla Arch `linux` 7.2.4-arch1-2 and on CachyOS
`7.3.0-rc2-3` (2026-09-14) / `7.2.5-1` (2026-09-15), with and without ntsync,
identical signature. CachyOS is NOT the venue (their issue template redirects
upstream bugs): file at bugzilla.kernel.org (mark as regression) + Cc
regressions@lists.linux.dev. Draft below adapted from the original CachyOS report.
Stable retest done: **7.2.5-1 still crashes** — the CachyOS v3 build only landed
2026-09-15 13:00 UTC (after the clang-22 `drm/gud` FORTIFY build block, CachyOS
issue #1031). Filing upstream is now the next step.

## System

- Laptop: Dell XPS 14 DA14260; CPU Intel Core Ultra X7 358H (16 threads, 6P+8E+2LP hybrid); iGPU Intel Arc B390 (Panther Lake); 32 GB RAM
- Kernel: `7.2.0-1-cachyos`, `7.2.4-3-cachyos`, `7.2.5-1-cachyos`, vanilla Arch `7.2.4-arch1-2`, `7.3.0-rc2-3-cachyos-rc` (all broken) vs `6.18.42/6.18.50-cachyos-lts` (works)
- Mesa: `3:26.3.0_devel` (cachyos-v3 mesa-git; 26.2.1 also tested — no difference)
- Steam native 1.0.0.87-3, Proton 11.0 / Proton Experimental / GE-Proton11-5 (identical failure on 7.2.0)
- Game: Red Dead Redemption 2 (Steam appid 1174180), Rockstar Launcher flow

## Symptom

Rockstar Launcher opens fine and its loading bar completes; on `7.2.0` RDR2.exe then runs ~2 s and dies during engine init ("Game Init", 0 GPU usage) — on `7.2.4` it survives ~15 s and briefly shows the game window before the same death (see retest below). The launcher shows the "game crashed" menu; Retry and Safe Mode fail the same way. With `WINEDEBUG=+seh` the fatal fault is:

```
Exception 0xc0000005 (EXCEPTION_ACCESS_VIOLATION)
info[1] = 0x28            (run 1: READ at 0x28 — NULL+0x28)
info[1] = 0xFFFFFFFFFFFFFFFF (runs 2..n: READ at -1)
rip = RDR2.exe + <offset varies per run>
```

A handled `EXCEPTION_ILLEGAL_INSTRUCTION` (0xc000001d) fires on a sibling thread just before the fatal AV. The faulting code offset differs on every run — a race-flavored signature, not a deterministic bug. (Note: the v4l/qcap `0xc0000094` divide-by-zero exceptions in the same log are launcher-subprocess noise, unrelated.)

## Bisection result

- `7.2.0-1-cachyos`: crashes 100% of attempts, every Proton, every renderer, every config.
- `6.18.42-1-cachyos-lts`: **game boots and runs** with an identical userspace (same prefix, same Proton, same launch options). First successful launch on this machine. Kernel-only regression.
- **Vanilla Arch `linux` 7.2.4-arch1-2 (2026-09-12): crashes identically** → upstream mainline regression, NOT CachyOS-specific. (Vanilla 7.1.9 doesn't boot at all on this PTL machine — black screen — which limits bisection below 7.2.)
- **CachyOS `7.3.0-rc2-3-cachyos-rc` (2026-09-14): crashes identically** → not fixed in current mainline development (7.3-rc2). Since 7.2.6's stable content is a subset of mainline 7.3-rc2, a fix in 7.2.5/7.2.6 is unlikely — the stable retest is a formality, not a blocker for filing. **Confirmed: `7.2.5-1-cachyos` still crashes (retest 2026-09-15).**

## Retest 2026-09-15 — `7.2.5-1-cachyos`: still crashes

- Timeline (process monitor + Rockstar log): `PlayRDR2.exe` 23:49:34 → `RDR2.exe`
  ~23:49:58 → crash 23:50:09 → full stack gone 23:50:13. Lifetime after
  `RDR2.exe` starts: ~11 s (7.2.4-3: ~15 s).
- Launcher log: `Game exited with code 0xc0000005 (3221225477)` +
  `crashdetection: Exit code 0xc0000005 indicates a fatal game exit (reason:
  STATUS_ACCESS_VIOLATION)`.
- New dump: `CrashLogs/reports/6f989adb-5c2e-4943-9b9f-84643a2c0e6a.dmp`
  (85 MB, 23:50:09).
- GE-Proton11-5, same prefix/launch options. No kernel/GPU errors during the
  crash; 0 PSR timeouts and 0 DSB errors in that window (rc2 showed 2 + 15) —
  the display noise is rc-only.

## Retest 2026-09-14 — `7.3.0-rc2-3-cachyos-rc`: still crashes

- Timeline (Steam console + Rockstar crash log): launcher 18:02:10 → `RDR2.exe`
  18:02:38 → game window "Red Dead Redemption 2" 18:02:50 → crash 18:02:54 →
  "Shutdown" 18:02:55.
- Launcher log: `Game exited with code 0xc0000005 (3221225477)` — `STATUS_ACCESS_VIOLATION`.
- New dump: `CrashLogs/reports/6675814b-b723-4774-9984-fc4c3dc7d20f.dmp` —
  exception `0xc0000005`, params `[0x0, 0xffffffffffffffff]` (identical signature).
- Display side on rc differs (see `notes/xe-psr-timeouts.md`): no "for PSR Idle
  for re-enable" bursts anymore, but 15 `DSB 0 poll error` messages appear during
  the game's modeset — unrelated to the crash (crash happens with and without
  those errors), but noteworthy for the display investigation.

## Retest 2026-09-12 — `7.2.4-3-cachyos`: still crashes

Same bug, same signature; the game now gets further than on 7.2.0 before dying.

| | 2026-08-30 (7.2.0-1) | 2026-09-12 (7.2.4-3) |
|---|---|---|
| Exception | `0xc0000005` ACCESS_VIOLATION | `0xc0000005` ACCESS_VIOLATION |
| Access | READ at `-1` (params `[0x0, 0xffffffffffffffff]`) | identical |
| Lifetime | ~2 s, no window | ~15 s, game window appears, then crash |

- Timeline (Steam console + Rockstar crash log): launcher 14:41:32 → `RDR2.exe`
  14:42:14 → game window "Red Dead Redemption 2" 14:42:26 → crash dump 14:42:29 →
  "Shutdown" 14:42:32.
- No kernel/GPU errors in `journalctl -k` around the crash.
- New dumps: `CrashLogs/reports/4e471260-5d06-4ff1-8175-2b56510b1ba0.dmp` +
  `RDR2-20260912-144229-2828.crash.log` (Aug 30: `fdebb011-….dmp`). The dumps are
  ~80 MB and carry the exception stream — not "empty" as previously noted.
- 7.2.1's futex/io_uring-futex fixes and 7.2.4's scheduler fixes did not address
  it. Upstream **7.2.5** (not yet packaged by CachyOS) has further futex-cleanup
  and PSR fixes — retest when it lands.

## Vanilla Arch test 2026-09-12 — upstream regression confirmed

Booted the official Arch `linux` 7.2.4-arch1-2 on this machine (same CachyOS
userspace, prefix, Proton Experimental). Three runs:

| Run | ntsync | Result |
|---|---|---|
| vanilla + default | on (`ntsync: up and running` in Steam console) | `0xc0000005`, died in ~15 s |
| vanilla + `PROTON_NO_NTSYNC=1` | off (no ntsync line) | `0xc0000005`, died in ~15 s |
| vanilla + `WINEDEBUG=+seh PROTON_LOG=1` | on | `0xc0000005`, trace captured |

- Rockstar launcher log: `Game exited with code 0xc0000005 (3221225477)` —
  `STATUS_ACCESS_VIOLATION`, same as CachyOS.
- Fatal record from the `+seh` trace (thread `09e4`):
  `code=c0000005 addr=0x14664F17D info[0]=0 info[1]=FFFFFFFFFFFFFFFF` — the same
  `[0x0, -1]` params as the 7.2.4-3 minidump. Handled `0xc000001d`
  (ILLEGAL_INSTRUCTION) fires on sibling threads `0998`/`09e4`/`09e8`/`09f8`
  beforehand; thread `09f0` loops on AVs with `info[1]=0x8` (all handled).
- No kernel-side errors in `journalctl -k` during the crash; **ntsync is ruled
  out** (crash identical with it disabled).
- The vanilla runs produced no minidump (crash handler wrote only
  `settings.dat`); the 7.2.4-3 dumps remain the best core evidence.
- **PSR oops also reproduces on vanilla 7.2.4**: repeated
  `xe: *ERROR* Timed out waiting for PSR Idle for re-enable` despite
  `xe.enable_psr=0` on the cmdline — separate upstream issue for the Intel DRM
  tracker.

**Conclusion**: mainline 7.2 regression (6.18 LTS works, vanilla 7.2.4 broken);
not caused by CachyOS patches or ntsync.

## Ruled out (all identical across 7.2.x)

- Renderer: DX12 (vkd3d-proton) and Vulkan (ANV native)
- Proton 11.0 / Experimental / GE-Proton11-5 (protonfixes `-fullscreen -vulkan` applied)
- gamescope wrapper with and without
- Fresh prefix (compatdata + shadercache wiped) and stale-prefix states
- Mesa 26.2.1 → mesa-git 26.3.0_devel
- NVAPI: `PROTON_ENABLE_NVAPI=1 DXVK_ENABLE_NVAPI=1 DXVK_NVAPI_ALLOW_OTHER_DRIVERS=1` (NvAPI_Initialize still reports "not found" — Intel-only)
- v4l device interactions (chmod 000 on /dev/video*, loopback removed)
- CPU affinity/cpuset (see "related" below) and CPU topology (full 16-CPU run)
- ntsync: disabled via `PROTON_NO_NTSYNC=1` on vanilla 7.2.4 — crash identical (ruled out 2026-09-12)

## Related datapoints on the same kernel

- **PSR display glitch**: `7.2.0` also oopses in the xe driver during fullscreen modesets:
  `WARNING intel_psr_activate+0x3cf [xe]` + `xe: *ERROR* Timed out waiting PSR idle state`
  (unaffected by `xe.enable_psr=0` / `xe.psr_safest_params=1`). No glitches observed on the LTS kernel so far.
  Still present on `7.2.4-3` and on **vanilla 7.2.4** (repeated "Timed out waiting for PSR Idle") — separate upstream issue. Baseline + the Panel Replay finding: `notes/xe-psr-timeouts.md`.
- Existing tracker hits: CachyOS/linux-cachyos **#992** ("7.2.0 silent HDMI loss, LTS works"), **#968** ("some games freezing"), and a Steam discussion "CachyOS constant crashing" (Subnautica 2, kernel 7.2.0-1-cachyos, crashes every 10–30 min).
- **Working control — Diablo IV (appid 2344520)**: 2026-09-14, same setup (`7.2.4-3-cachyos`, Arc B390, no compatibility tool configured → default Proton Experimental `experimental-11.0-20260910b`) runs flawlessly out of the box on the 4K external monitor at medium settings; lowered to low only to smooth occasional stutter. So the RDR2 crash is **game-specific**, not a general Proton/DX12/7.2 gaming breakage on this hardware.
- Linux 7.2's headline change is a cache-aware scheduler (LLC task co-location) — a plausible area for wine thread-scheduling regressions; ntsync was also a candidate but is now ruled out.
- **2026-09-12: no third-party report found** — searched CachyOS tracker + forum, Proton tracker, GitHub-wide, and bugzilla.kernel.org (queries: RDR2, "Red Dead", "wine 7.2", "PSR idle"/"PSR re-enable"/"panther lake psr" — zero matches). lore.kernel.org (LKML/regressions list) is behind Anubis anti-bot and could not be searched programmatically; do a browser check before filing.
- Upstream PSR tickets on the Intel DRM tracker (`gitlab.freedesktop.org/drm/xe/kernel`): **#8564** "PTL: PSR and VRR can cause screen corruption" (open, 2026-07-06), **#9196** "xe/PTL: eDP-2 … PHY B failed to request refclk" (open, 2026-09-08); closed CI issues #5883/#2186 carry the same `Timed out waiting for PSR Idle for re-enable` string. Reference these when filing the PSR bug.

## Evidence files (local, if a maintainer needs them)

- RDR2 crash dumps: `~/.local/share/Steam/steamapps/compatdata/1174180/pfx/drive_c/users/steamuser/AppData/Local/Rockstar Games/Red Dead Redemption 2/CrashLogs/`
  - 2026-09-15 (7.2.5-1): `reports/6f989adb-5c2e-4943-9b9f-84643a2c0e6a.dmp`
  - 2026-09-12 (7.2.4-3): `reports/4e471260-5d06-4ff1-8175-2b56510b1ba0.dmp` + `RDR2-20260912-144229-2828.crash.log`
  - 2026-08-30 (7.2.0-1): `reports/fdebb011-c2d5-4707-b7fb-4dc18c46d53e.dmp`
- WINEDEBUG `+seh` trace, vanilla 7.2.4 (2026-09-12, ~1 MB): `~/steam-1174180.log` (since deleted; regenerate with `WINEDEBUG=+seh PROTON_LOG=1` if needed)
- Rockstar launcher log (game exit code): `.../Documents/Rockstar Games/Launcher/launcher.log`
- Steam console: `~/.local/share/Steam/logs/console-linux.txt`
- PSR oops: `journalctl -k` (intel_psr_activate, "Timed out waiting PSR idle state")

## Suggested next steps

1. ~~Retest on **7.2.5** when packaged~~ Done 2026-09-15: still crashes → file upstream now.
2. File upstream — bugzilla.kernel.org, mark as regression, Cc regressions@lists.linux.dev; lead with scheduler/mm and the `+seh` signature; ntsync ruled out, LTS 6.18 works, vanilla 7.2.4 + CachyOS 7.2.5/7.3-rc2 all break.
3. PSR `Timed out waiting for PSR Idle` is a separate, concrete bug — Intel DRM tracker (gitlab.freedesktop.org/drm/xe/kernel), reproduces on vanilla with `xe.enable_psr=0`
4. Bisection is limited: vanilla 7.1.9 doesn't boot on this PTL machine

---

### Related machine note (kept out of the GitHub issue)

During the investigation, **ananicy-cpp** was found pinning the entire system
(`system.slice` + `user.slice` cpuset = 12-15, the 4 low-power cores) via its
`apply_cpuset` feature on hybrid CPUs. Disabled with `apply_cpuset = false` in
`/etc/ananicy.d/ananicy.conf`; the whole desktop now uses all 16 CPUs. Not the
RDR2 cause, but a real machine fix worth knowing about.
