# RDR2 (Steam) crashes at engine init on this machine — investigation log

Status: **unresolved** (last explored 2026-08-27). Game has NEVER run on this
machine (crash dumps since 2026-08-14). Ongoing; see TODO.

## Symptom

Steam → Rockstar Games Launcher opens fine (loading bar completes) → RDR2.exe
starts → crashes during **Game Init** (all engine pools 0, 0 GPU usage, empty
crash dump) → launcher shows "the game crashed" menu (Retry / Safe Mode both
fail). Safe mode gets marginally further, still crashes.

## Environment

- Intel **Arc B390 (Panther Lake/PTL)** iGPU, `mesa 3:26.2.1-1` (ANV Vulkan)
- Steam native (`steam 1.0.0.87-3`), RDR2 appid **1174180**, installed
- Protons tried: `Proton 11.0` (proton-11.0-1b), `Proton - Experimental`
  (11.0-20260805), **GE-Proton11-5** (compatibilitytools.d, installed via
  ProtonUp-Qt; protonfixes auto-applies `-fullscreen -vulkan` for RDR2)
- Launcher originally wrapped in gamescope via per-game LaunchOptions
  (`gamescope -W 1920 -H 1200 -r 60 -f -- %command%`) — since removed; crash
  happens with AND without gamescope
- Renderer: `system.xml` now `<API>kSettingAPI_Vulkan</API>` (was DX12; both
  crash identically). Config file:
  `~/.local/share/Steam/steamapps/compatdata/1174180/pfx/drive_c/users/steamuser/Documents/Rockstar Games/Red Dead Redemption 2/Settings/system.xml`
  (backup: `system.xml.bak-20260827`)

## Evidence trail (paths for future agents)

- RDR2 crash logs (empty debug dumps, custom format, no fault info):
  `.../compatdata/1174180/pfx/drive_c/users/steamuser/AppData/Local/Rockstar Games/Red Dead Redemption 2/CrashLogs/`
  (minidumps in `reports/` are Rockstar's CUSTOM stream types — not parseable
  with standard minidump tooling)
- Launcher log: `.../Documents/Rockstar Games/Launcher/launcher.log` (+rotated
  `.01-.04`) — always ends "Application quit requested (exit code: 0)" after
  the game dies; no game exit code logged
- Steam console (contains all Proton/wine output): `~/.local/share/Steam/logs/console-linux.txt`
- Protonfixes log (GE): `~/.cache/protonfixes/protonfixes.log` — shows
  `Running protonfixes on "GE-Proton11-5"` + `Adding argument -fullscreen -vulkan`
  at 10:28 on the crash day
- Manual launcher run (NOT representative — game never starts without Steam's
  S: drive mapping, but proves launcher/DXVK/ANV rendering works):
  `/tmp/opencode/rdr2-manual.log`
- Prefix churn observed: `Proton: Prefix has an invalid version?!` while
  switching GE ↔ 11.0 (compatdata `version` file = `11.0-100`)
- ProtonDB: RDR2 overall Gold/Platinum (1428 reports) — issue is
  machine/hardware-specific, not a general Proton break

## What has NOT worked

- DX12 (vkd3d) and Vulkan (ANV) renderers — identical crash
- Proton 11.0 / Experimental / GE-Proton11-5 — identical crash
- gamescope wrapper and no wrapper — identical crash
- Safe Mode — crashes later in the load

## Known upstream lead

"RDR2 crashes on **Intel** GPUs **in fullscreen**" — Linux Mint forums
(Dec 2025, A770): fixed by gamescope for those users (our gamescope run still
crashed, so either not the same cause or gamescope-on-PTL has its own bug).
CachyOS forum thread with the EXACT same symptom (black screen + loading bar →
engine-init crash, user was on NVIDIA laptop): one user fixed it by removing
all launch options + reinstalling; no root cause identified.

## Next steps

1. **Decisive capture (in flight)**: relaunch with launch options
   `WINEDEBUG=+seh %command%` → crash → grep the tail of
   `~/.local/share/Steam/logs/console-linux.txt` for the exception stack
   (also look for any `wine: Unhandled exception` block). A `PROTON_LOG=1
   %command%` run writes `proton_log.txt` into the game dir — check there too.
2. **Clean slate**: delete `compatdata/1174180` (back up; loses only in-game
   settings/profiles) + `steamapps/shadercache/1174180` (fossilize/foz cache)
   and retry — clears the invalid-version prefix churn and any bad shader cache.
3. If the stack points into ANV/mesa: `pacman -Syu` mesa (CachyOS rolling;
   B390/PTL is new — driver fixes land often), then search
   `ValveSoftware/Proton#3291` (RDR2 mega-thread) and mesa/ANV issues for
   PTL-specific RDR2 reports.
4. If fullscreen-class: try windowed/borderless before launch (no official
   `-windowed` arg; would edit the game settings once the game boots once).

## Related config on this machine

- Gaming workspace (`name:gaming`, ID -1337) routes `steam_app.*` windows
  there (CachyOS `windowrules.lua`); **SUPER+SHIFT+G** jumps to it
  (added 2026-08-27 in `binds.lua`; no CLI dispatch exists for workspace on
  this hyprland-lua build). Workspace is non-default since 2026-08-23
  (`workspaces.lua`).
- gamescope 3.16.25 installed; "Use gamescope" launch options were per-game
  and are now cleared for 1174180.

## TODO (future agent)

- Read the console log after the WINEDEBUG run; record the faulting module/address.
- Execute the clean-prefix + shader-cache wipe; retry; document result.
- If fixed: document the working recipe (proton version, renderer, launch
  options) and mark this note resolved.
- Consider updating this note with the final `system.xml`/launch-options state.
