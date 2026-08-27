# RDR2 (Steam) crashes at engine init on this machine — investigation log

Status: **unresolved — real fault isolated, cause not yet fixed**
(last explored 2026-08-27). Game has NEVER run on this machine (crash dumps
since 2026-08-14). See TODO.

## Symptom

Steam → Rockstar Games Launcher opens fine (loading bar completes) → RDR2.exe
starts → crashes during **Game Init** (all engine pools 0, 0 GPU usage, empty
crash dump) → launcher shows "the game crashed" menu (Retry / Safe Mode both
fail). Safe mode gets marginally further, still crashes.

## The REAL fault (from WINEDEBUG trace `~/steam-1174180.log`, 41 MB)

RDR2.exe (pid 09b4 in the log) runs ~2 s after spawn, then dies with:

```
warn:seh:dispatch_exception backtrace: --- Exception 0xc0000005.
code=c0000005 (EXCEPTION_ACCESS_VIOLATION), READ at address 0x28   → NULL+0x28 deref
rip = RDR2.exe + 0x2C8363F   (stack entirely inside RDR2.exe)
```

Immediately preceding the fault, the game's GPU/display detection:
1. SetupAPI device-tree walk (`CM_Get_DevNode_Status`/`CM_Get_Child` — wine
   stubs) at 1776.223–228
2. `d3d11.dll` + `nvapi64.dll` (DXVK-NVAPI) load; `NvAPI_Initialize` FAILS
   ("NVIDIA or other suitable device not found") at 1776.26
3. ~10 ms later the AV. The game's own WER handler runs (writes the crash log),
   so wine DID dispatch this exception — the AV itself is the fatal event.

The game's `.text` section is PACKED (high-entropy bytes on disk) — static
disassembly impossible. The v4l DIV0 crashes in the same log (10× `0xc0000094`
in `qcap.so`) are **LAUNCHER noise** — they happen at 1746s, ~28 s BEFORE
RDR2.exe spawns, across four launcher subprocess pids. **Red herring.**

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

## Related machine issue: display glitching during fullscreen (xe/PSR)

Recurring **screen glitch** during the game's fullscreen transitions. Kernel
journal: `WARNING ... intel_psr_activate+0x3cf [xe]` +
`xe: *ERROR* Timed out waiting PSR idle state` — a kernel bug on this
Panther Lake panel during modesets. Status:

- `xe.enable_psr=0` added to the boot cmdline (`/etc/default/limine`) — did
  NOT prevent the glitch (the PSR state machine still runs in the modeset
  path); the oops recurred at 11:44 even with PSR off
- `xe.psr_safest_params=1` added to the cmdline (2026-08-27, limine.conf
  regenerated via `limine-update`) — **untested yet** (needs a reboot)
- No newer kernel available (7.2.0-1-cachyos is current) — likely needs an
  upstream xe/i915 fix; track in a future check
- modprobe.d drop-in `/etc/modprobe.d/xe-psr-off.conf` exists too (inert;
  kernel cmdline is the effective source)
- If the glitch persists after reboot with safest params: file/track as its
  own hardware note (xps14 PSR bug), document `wlr-randr` re-modeset as a
  stopgap

## Remaining steps (in order)

1. **Reboot** (clears glitch, applies `psr_safest_params=1`) → re-arm the
   fixed watcher → one launch → gdb captures the runtime fault → identify the
   NULLed structure from the unpacked instruction
2. **gamescope + Vulkan** combo — the Mint-thread Intel fix, never tested
   together (gamescope was only tried with DX12)
3. Depending on the gdb result: targeted fix (e.g., a game setting that
   bypasses the failing probe, a DXVK/wine knob, or filing the bug upstream
   with the captured instruction)

## Related config on this machine

- Gaming workspace (`name:gaming`, ID -1337) routes `steam_app.*` windows
  there; **SUPER+SHIFT+G** jumps to it (binds.lua; no CLI workspace dispatch
  exists on this hyprland-lua build)
- gamescope 3.16.25 installed; RDR2's per-game gamescope launch options were
  cleared during testing

## TODO (future agent)

- Run the gdb capture (steps above) and record the faulting instruction +
  registers from `/tmp/opencode/rdr2-gdb-u/gdb-*.log`
- Test `psr_safest_params=1`; if the glitch persists, open a dedicated
  hardware note and check upstream xe fixes on kernel updates
- If fixed: document the working recipe (proton, renderer, launch options)
  and mark this note resolved
