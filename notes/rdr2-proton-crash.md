# RDR2 (Steam) crashes at engine init on this machine — investigation log

Status: **unresolved — root cause identified** (last explored 2026-08-27).
Game has NEVER run on this machine (crash dumps since 2026-08-14). See TODO.

## Symptom

Steam → Rockstar Games Launcher opens fine (loading bar completes) → RDR2.exe
starts → crashes during **Game Init** (all engine pools 0, 0 GPU usage, empty
crash dump) → launcher shows "the game crashed" menu (Retry / Safe Mode both
fail). Safe mode gets marginally further, still crashes.

## Root cause (confirmed from WINEDEBUG trace `~/steam-1174180.log`, 41 MB)

The game's init loads the VFW capture chain (`avicap32 → msvfw32 → quartz →
qcap`) and enumerates video devices. Wine's `qcap.so` probes the host's
`/dev/video*` and **divides by zero** when a device returns a bad fps:

```
err:quartz:v4l_device_create Failed to get fps: Inappropriate ioctl for device.
warn:seh:dispatch_exception backtrace: --- Exception 0xc0000094 at qcap.so + 0x2a36
err:seh:call_seh_handlers invalid frame ... => unable to dispatch exception.
```

0xc0000094 (EXCEPTION_INT_DIVIDE_BY_ZERO) with an undispatchable frame kills
the process (10 occurrences in the log = every attempt). This machine has
35+ `/dev/video*` nodes (Intel IPU7 camera video0-31 + v4l2loopback
`/dev/video33`), so wine's probe always hits a broken device. REMOVING the
v4l2loopback (camera stack stopped, video33 gone) did NOT fix it — the IPU7
nodes alone still trigger the crash. (On typical desktops with no webcam,
wine finds nothing and the game proceeds — which is why RDR2 normally works.)

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
all launch options + reinstalling; no root cause identified. The v4l qcap
divide-by-zero above supersedes both as the likely cause on THIS machine.

## Related machine issue found during testing (2026-08-27)

During the game attempts the **display started glitching** even after the game
exited. Kernel journal shows an oops in the xe driver:
`intel_psr_activate` + `xe: *ERROR* Timed out waiting PSR idle state`
(10:47, PSR = Panel Self Refresh). Workaround installed:
`/etc/modprobe.d/xe-psr-off.conf` → `options xe enable_psr=0`
(the param is boot-only; needs a reboot to take effect). Re-modeset
(`wlr-randr --output eDP-1 --mode 1920x1200@120.000999Hz`) was applied as a
stopgap. If the glitch persists after reboot with PSR off, revisit.

## Next steps

1. **Try `WINEDLLOVERRIDES="avicap32=" %command%`** as launch options —
   disables the VFW capture DLL so wine never probes v4l. If the game then
   boots (it shouldn't need video capture), this is the fix.
2. **Clean slate** (if step 1 fails): delete `compatdata/1174180` (back up;
   loses only in-game settings/profiles) + `steamapps/shadercache/1174180`
   and retry — clears the invalid-version prefix churn and any bad shader cache.
3. If the game still probes v4l: hide the devices from the container
   (pressure-vessel bind-mount manipulation) or unload `intel_ipu7_isys`
   before gaming (kills the camera until reloaded) — heavier.
4. **Reboot for the PSR fix** and re-check the display; also retest RDR2
   afterwards (a clean GPU state may matter).

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
