# RDR2 (Steam) crashes at engine init on this machine — investigation log

Status: **RESOLVED — kernel regression** (2026-08-27). RDR2 boots and runs on
the **LTS kernel (`6.18.42-1-cachyos-lts`)**; the init crash only occurs on
`7.2.0-1-cachyos`. First-ever successful game start on this machine. Remaining
post-boot issue: Social Club entitlement (account sign-in in the fresh
prefix), not a crash.

## Current setup / trade-off (2026-08-28)

- **Boot default = `7.2.0-1-cachyos`** (daily driver: full audio, all
  hardware enablement). `default_entry: 0`, `remember_last_entry: no` in
  `/boot/limine.conf` (header survives `limine-update` regeneration).
- **RDR2 sessions: reboot → press a key at the limine menu → pick
  `linux-cachyos-lts`.** On LTS the game works, but **internal speakers/
  headphones are dead** (the 6.18 SOF stack has no Panther Lake SoundWire
  machine driver — HDMI-only; Bluetooth audio works). This is the same
  PTL-enablement gap inverted: 7.2.0 has audio but crashes RDR2.
- **Retest 7.2.0 on every kernel update** (and once the filed CachyOS bug —
  see `rdr2-kernel-regression-report.md` — is fixed): the goal is ONE kernel
  that runs both.

## Watch list (researched 2026-08-28 — what to retest when it lands)

- **Kernel 7.3** (merge window open Aug 2026; final ~Sep–Oct): headline
  changes include a **scheduler/SMP overhaul** (IPI-wait preemption,
  P99 −90%, gaming min-fps boosts, better asymmetric P/E-core support) —
  the 7.2 cache-aware scheduler change is our RDR2 regression suspect, so
  retest RDR2 on 7.3 (hope: regression fixed → one kernel for game + audio).
  Also in 7.3 DRM/xe: Xe3 Panther Lake Peak Bandwidth Threshold (display
  power), Nova Lake default-on, plus a Linus-fixed xe memory bug — retest
  the PSR glitch on 7.3.
- **Mesa 26.3** (already installed as cachyos mesa-git 26.3.0_devel): ANV
  compressed-memory default for Xe2+ general buffers → DXVK gains up to
  ~5% on Arc; ANV Vulkan video H.265 compliance fix. Keep mesa-git current.
- The CachyOS bug report draft (`rdr2-kernel-regression-report.md`) is the
  vehicle for the 7.2.0 regression; paste-ready copy at
  `/tmp/opencode/rdr2-cachyos-bug-report.md`.
- Anno 1404 (Steam non-Steam install, extracted to `/home/afr/Games/Anno1404-setup/`)
  is a separate track, on hold by user request.

## Symptom

Steam → Rockstar Games Launcher opens fine (loading bar completes) → RDR2.exe
starts → crashes during **Game Init** (all engine pools 0, 0 GPU usage, empty
crash dump) → launcher shows "the game crashed" menu (Retry / Safe Mode both
fail). Safe mode gets marginally further, still crashes.

## ROOT CAUSE (confirmed 2026-08-27)

**The kernel: `7.2.0-1-cachyos`.** On `6.18.42-1-cachyos-lts` (installed and
bootable via the limine menu) the game boots and runs past init with zero
changes to any game config. The crash signature on 7.2.0 — RDR2.exe
`EXCEPTION_ACCESS_VIOLATION` at varying addresses (reads at 0x28, -1, …)
with a handled `0xc000001d` on a sibling thread — is a race-flavored
regression in 7.2.0 (likely a wine-relevant subsystem change: futex/vma/
sync behavior). Nothing userspace fixed it: renderer, Proton (11.0 /
Experimental / GE), gamescope, prefix, caches, mesa (26.2.1 → git),
NVAPI (incl. `ALLOW_OTHER_DRIVERS`), v4l device hiding, cpuset/affinity —
all ruled out. The game's `0xc000001d`/AV pair and the PSR oops (below) both
point at the new-kernel stack.

Actions:
- Report the regression upstream (CachyOS bug tracker; kernel 7.2.0 + RDR2/
  wine init AV).
- For gaming: boot the LTS entry (`linux-cachyos-lts` in the limine menu).
  Consider making LTS the default boot entry if 7.2.0 misbehaves elsewhere.
- The PSR glitch should be re-checked on LTS — may share the same kernel
  root cause.

Post-boot note: after the first successful launch the game may report
"Social Club account not entitled to RDR2" — that is the fresh-prefix account
sync (the game never ran on this machine before), fixed by signing into the
Rockstar account in the launcher and relaunching. Not a crash.

## Dead ends (all tested 2026-08-27, all ruled out)

| Attempt | Result |
|---|---|
| DX12 (vkd3d) ↔ Vulkan (ANV) renderers | identical crash |
| Proton 11.0 / Experimental / GE-Proton11-5 | identical crash (GE confirmed via protonfixes log; it auto-applies `-fullscreen -vulkan`) |
| gamescope wrapper (`-W 1920 -H 1200 -r 60 -f`) with DX12 | identical crash (NOTE: gamescope+Vulkan combo NEVER tested together) |
| Removing the v4l2loopback + camera stack (video33 gone) | identical crash |
| `chmod 000 /dev/video*` (unopenable by wine) | identical crash (perms since restored) |
| `WINEDLLOVERRIDES="avicap32="` (disable VFW capture DLL) | identical crash |
| `PROTON_ENABLE_NVAPI=1 DXVK_ENABLE_NVAPI=1` (fake NVIDIA) | identical crash (launcher once froze instead — behavior change, unreadable) |
| Clean slate: fresh `compatdata/1174180` + `shadercache/1174180` (backs up in `.bak-20260827`) | identical crash |
| **mesa-git 26.3.0_devel** (cachyos-v3, replaced mesa 26.2.1) | identical crash (missing crash-menu once — behavior shift only) |
| `LD_PRELOAD` signal dumper (runtime instruction capture) | **stripped by pressure-vessel** — dead end |
| `DXVK_NVAPI_ALLOW_OTHER_DRIVERS=1` (fake NVIDIA on any driver) | NvAPI_Initialize STILL failed (option exists in the binaries but no effect) — ruled out |
| Full 16-CPU run (after the cpuset fix below) | identical crash — CPU topology ruled out |
| **gamescope + Vulkan** (the Mint-thread Intel fix — only ever tested with DX12 before) | identical crash — ruled out. Notable: **no PSR glitch** on this run |

## Environment

- Intel **Arc B390 (Panther Lake/PTL)** iGPU; currently **mesa-git
  26.3.0_devel** (was 26.2.1; swap is reversible: `pacman -S mesa
  lib32-mesa`), ANV Vulkan
- Kernel `7.2.0-1-cachyos` (no update available)
- Steam native (`steam 1.0.0.87-3`), RDR2 appid 1174180
- Protons tried: 11.0 / Experimental / GE-Proton11-5 (see table)
- Renderer setting: `<API>kSettingAPI_Vulkan</API>` in
  `.../Documents/Rockstar Games/Red Dead Redemption 2/Settings/system.xml`
  (fresh prefix currently has NO system.xml — game crashes before writing it)
- ProtonDB: RDR2 Gold/Platinum overall — machine-specific issue

## Evidence trail (paths for future agents)

- WINEDEBUG trace (the key file): `~/steam-1174180.log` (41 MB; `PROTON_LOG`
  output lands here in modern Proton)
- RDR2 crash logs (empty shells): `.../compatdata/1174180/pfx/drive_c/users/steamuser/AppData/Local/Rockstar Games/Red Dead Redemption 2/CrashLogs/`
  (minidumps in `reports/` use Rockstar's custom stream types — not parseable
  with standard tooling)
- Launcher log: `.../Documents/Rockstar Games/Launcher/launcher.log` (+.01–.04)
- Steam console: `~/.local/share/Steam/logs/console-linux.txt`
- Protonfixes (GE): `~/.cache/protonfixes/protonfixes.log`
- Manual launcher run (proves launcher/DXVK/ANV rendering works; game never
  auto-starts without Steam context): `/tmp/opencode/rdr2-manual.log`
- Old prefix + shader cache backed up at `compatdata/1174180.bak-20260827` /
  `shadercache/1174180.bak-20260827`

## Debug tooling status

- **ptrace_scope=0** persisted via `/etc/sysctl.d/99-ptrace.conf` (set
  2026-08-27) — user-level `gdb -p` attach works, no pkexec needed
- Watcher script `/tmp/opencode/rdr2-gdb-watch.sh` — SIGSTOPs RDR2.exe the
  instant it spawns, then gdb-attaches to catch the fault (instruction bytes
  + registers at runtime-unpacked RIP). Lesson learned: `pgrep -f
  'RDR2\.exe$'` ALSO matches `PlayRDR2.exe` and the Steam **reaper**
  (`.../reaper SteamLaunch AppId=1174180 ...PlayRDR2.exe`) — a SIGSTOP'd
  reaper breaks Steam's game tracking (frozen process, "Steam didn't notice
  the game"). Current watcher uses exclusion-based matching
  (PlayRDR2/reaper/Launcher/steam excluded, real RDR2.exe only).
  Run: `nohup /tmp/opencode/rdr2-gdb-watch.sh &` then launch the game; results
  in `/tmp/opencode/rdr2-gdb-u/`.

## Related machine issue found during testing (2026-08-27)

### The cpuset pin — whole machine on 4 low-power cores (FIXED)

The ENTIRE machine was cpuset-pinned to **CPUs 12-15** (`system.slice` +
`user.slice` `cpuset.cpus.effective` = 12-15; every process incl. PID 1's
descendants, Steam, Hyprland). Perpetrator: **ananicy-cpp** (CachyOS's
auto-niceness daemon) — its `apply_cpuset` feature (default ON) pins cgroups
on hybrid CPUs, re-applied every 15 s check cycle. Consequences:
- The whole desktop ran on 2E+2LP cores (Panther Lake 6P+8E+2LP).
- `taskset -c 0-7 %command%` launch options failed ("doesn't launch",
  Play→Cancel) because children cannot widen beyond the parent cpuset.

Fix (durable):
1. Append `apply_cpuset = false` to `/etc/ananicy.d/ananicy.conf`
2. `systemctl restart ananicy-cpp`
3. `systemctl set-property --runtime system.slice AllowedCPUs=0-15` and
   `... user.slice AllowedCPUs=0-15` (runtime; resets at reboot, but nothing
   re-pins anymore)

Verified stable across ananicy's check cycle. This is a REAL machine fix
independent of RDR2 — the whole desktop now uses all 16 CPUs. The RDR2 crash
persists regardless (topology ruled out).

### Display glitching during fullscreen (xe/PSR) — confirmed kernel bug

Recurring **screen glitch** during the game's fullscreen transitions. Kernel
journal: `WARNING ... intel_psr_activate+0x3cf [xe]` +
`xe: *ERROR* Timed out waiting PSR idle state`. Status:
- `xe.enable_psr=0` + `xe.psr_safest_params=1` in the boot cmdline —
  the oops STILL fires (12:06:46) → confirmed unfixed kernel bug on this
  Panther Lake panel during modesets
- No newer kernel available (7.2.0-1-cachyos current) — track on kernel updates
- Datapoint: the **gamescope run had no glitch** — gamescope's compositing
  may avoid the triggering modeset path
- Stopgap: reboot clears the glitch; `wlr-randr --output eDP-1 --mode
  1920x1200@120.000999Hz` re-modeset as an immediate relief
- modprobe.d drop-in `/etc/modprobe.d/xe-psr-off.conf` exists (inert; cmdline
  is the effective source)

## Remaining steps (in order)

1. **One final capture run** (planned 2026-08-27, post-cpuset-fix):
   launch options `PROTON_LOG=1 WINEDEBUG=+seh %command%`, read the fresh
   `~/steam-1174180.log` — confirm whether the fault signature changed with
   all 16 CPUs available (varied across runs: reads at 0x28, 0xFFFFFFFFFFFFFFFF,
   … — race/incompat signature). See TODO for the outcome.
2. If still failing: treat as **upstream-watch** — kernel (PSR + PTL fixes),
   mesa, Proton/wine, and the RDR2 mega-thread `ValveSoftware/Proton#3291`
   for Intel reports. Revisit monthly or on updates.
3. If a future kernel/mesa/Proton update lands: re-run the capture and
   re-evaluate.

## Related config on this machine

- Gaming workspace (`name:gaming`, ID -1337) routes `steam_app.*` windows
  there; **SUPER+SHIFT+G** jumps to it (binds.lua; no CLI workspace dispatch
  exists on this hyprland-lua build)
- gamescope 3.16.25 installed; RDR2's per-game gamescope launch options were
  cleared during testing
- **Debug infra left behind** (2026-08-27): `kernel.yama.ptrace_scope=0` in
  `/etc/sysctl.d/99-ptrace.conf` (user-level gdb attach works); watcher
  script `/tmp/opencode/rdr2-gdb-watch.sh` (SIGSTOP+gdb, excludes
  reaper/PlayRDR2/self); `~/.cache/protonfixes/protonfixes.log`; the camera
  stack + `/dev/video*` perms were restored after testing

## TODO (future agent)

- Run the final capture (Remaining steps #1) and record the fault signature.
- Test `psr_safest_params=1` result is CONFIRMED NOT sufficient (oops at
  12:06:46) — the PSR glitch needs an upstream xe fix; re-check on kernel
  updates; consider a dedicated hardware note if it persists.
- Verify the cpuset fix survives a reboot (expected: yes, nothing re-pins;
  the `--runtime` slice lift resets, ananicy's `apply_cpuset=false` holds).
- If fixed: document the working recipe (proton, renderer, launch options)
  and mark this note resolved.
