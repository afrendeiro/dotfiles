# [BUG] RDR2 (Steam/Proton) crashes during engine init on 7.2.0-1-cachyos; works on 6.18.42-1-cachyos-lts

Status: **ready to file** — draft for https://github.com/CachyOS/linux-cachyos/issues (2026-08-27).

## System

- Laptop: Dell XPS 14 DA14260; CPU Intel Core Ultra X7 358H (16 threads, 6P+8E+2LP hybrid); iGPU Intel Arc B390 (Panther Lake); 32 GB RAM
- Kernel: `7.2.0-1-cachyos` (broken) vs `6.18.42-1-cachyos-lts` (works)
- Mesa: `3:26.3.0_devel` (cachyos-v3 mesa-git; 26.2.1 also tested — no difference)
- Steam native 1.0.0.87-3, Proton 11.0 / Proton Experimental / GE-Proton11-5 (identical failure on 7.2.0)
- Game: Red Dead Redemption 2 (Steam appid 1174180), Rockstar Launcher flow

## Symptom

Rockstar Launcher opens fine and its loading bar completes; RDR2.exe then runs ~2 s and dies during engine init ("Game Init", 0 GPU usage, empty crash dump). The launcher shows the "game crashed" menu; Retry and Safe Mode fail the same way. With `WINEDEBUG=+seh` the fatal fault is:

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
- **Vanilla Arch `linux` (7.1.9-arch1-2): does not boot on this machine at all** — black screen immediately after the bootloader. CachyOS's kernels carry Panther Lake (PTL) platform enablement that mainline 7.1.9 lacks. The CachyOS issue-template checkbox "reproduced on Arch Linux's `linux` kernel" therefore cannot be satisfied on this hardware; this report is the CachyOS-side record. When Arch's mainline reaches 7.2.0, retest to separate "mainline 7.2 regression" from "CachyOS 7.2.0 patches" (TODO).

## Ruled out (all identical on 7.2.0)

- Renderer: DX12 (vkd3d-proton) and Vulkan (ANV native)
- Proton 11.0 / Experimental / GE-Proton11-5 (protonfixes `-fullscreen -vulkan` applied)
- gamescope wrapper with and without
- Fresh prefix (compatdata + shadercache wiped) and stale-prefix states
- Mesa 26.2.1 → mesa-git 26.3.0_devel
- NVAPI: `PROTON_ENABLE_NVAPI=1 DXVK_ENABLE_NVAPI=1 DXVK_NVAPI_ALLOW_OTHER_DRIVERS=1` (NvAPI_Initialize still reports "not found" — Intel-only)
- v4l device interactions (chmod 000 on /dev/video*, loopback removed)
- CPU affinity/cpuset (see "related" below) and CPU topology (full 16-CPU run)

## Related datapoints on the same kernel

- **PSR display glitch**: `7.2.0` also oopses in the xe driver during fullscreen modesets:
  `WARNING intel_psr_activate+0x3cf [xe]` + `xe: *ERROR* Timed out waiting PSR idle state`
  (unaffected by `xe.enable_psr=0` / `xe.psr_safest_params=1`). No glitches observed on the LTS kernel so far.
- Existing tracker hits: CachyOS/linux-cachyos **#992** ("7.2.0 silent HDMI loss, LTS works"), **#968** ("some games freezing"), and a Steam discussion "CachyOS constant crashing" (Subnautica 2, kernel 7.2.0-1-cachyos, crashes every 10–30 min).
- Linux 7.2's headline change is a cache-aware scheduler (LLC task co-location) — a plausible area for wine thread-scheduling regressions; ntsync is also active on this kernel.

## Evidence files (local, if a maintainer needs them)

- WINEDEBUG trace (full, 41 MB): `~/steam-1174180.log`
- RDR2 crash dumps: `~/.local/share/Steam/steamapps/compatdata/1174180/pfx/drive_c/users/steamuser/AppData/Local/Rockstar Games/Red Dead Redemption 2/CrashLogs/`
- Steam console: `~/.local/share/Steam/logs/console-linux.txt`
- PSR oops: `journalctl -k` (intel_psr_activate, "Timed out waiting PSR idle state")

## Suggested next steps for maintainers

1. Bisect 7.x scheduler changes (cache-aware placement) against wine games
2. Check ntsync interaction (game runs with ntsync on both kernels)
3. Confirm whether the PSR oops shares the same root cause

---

### Related machine note (kept out of the GitHub issue)

During the investigation, **ananicy-cpp** was found pinning the entire system
(`system.slice` + `user.slice` cpuset = 12-15, the 4 low-power cores) via its
`apply_cpuset` feature on hybrid CPUs. Disabled with `apply_cpuset = false` in
`/etc/ananicy.d/ananicy.conf`; the whole desktop now uses all 16 CPUs. Not the
RDR2 cause, but a real machine fix worth knowing about.
