# Random hard freezes — total hang, no kernel trace (2026-09-01 →)

Status: **investigating**. First cluster began 2026-09-01 evening (on
`7.2.0-1-cachyos`), repeated 2–3× on 2026-09-02. No cause identified yet;
nothing in the logs explains it. Report new occurrences + the checklist
results back to keep this note current.

## Symptom

- Machine **completely freezes**: no input response, no disk/network
  activity, screen stays frozen on the last frame (no noise/black), must
  hard-shutdown (user waited < 1 min, AC power, no obvious pattern or
  trigger app).
- Distinct from the EC power-loss bug (`xps14-da14260-hard-reset.md`):
  that one cuts power with a blink code and happens on battery — this is
  a silent hang **on AC**. Same PTL platform, so treat as possibly related
  class of platform instability.

## Timeline (2026-09-02)

- 12:48 — boot (7.2.0-1-cachyos; 7.2.2 pkg installed 15:31, not booted yet)
- 16:13 — herdr coredump (userspace; herdr's own write_fmt crash — noise)
- 16:54:38 — `gst-launch` (ipu7-camera-proxy, PID 1658): "A lot of buffers
  being dropped" — camera pipeline struggles 7 s before the log ends
- **16:54:45 — journal stops mid-line (noctalia pam setuid msg), nothing
  after** — the freeze
- ~17:11 — hard reboot into `7.2.2-1-cachyos` (current)

## Evidence

- **Silent log stop**: `journalctl -b -1` ends 16:54:45 with no panic, no
  OOM, no watchdog, no MCE, no `BUG:` — the freeze left zero kernel trace
  (logging simply ceased before anything could record a cause).
- pacman.log shows **no relevant change at onset**: only `r`+`tk`+`zip`
  installed 2026-09-01 10:01, partial lib upgrade (gtest/abseil/ada/
  libgcrypt) 2026-09-02 15:31 — crashes began ~Sep 1 evening on a kernel
  that had run fine for days. Not update-triggered.
- Camera correlation is weak (proxy always runs; dropped buffers may be a
  symptom of the system already hanging, not the cause) but is the only
  event adjacent to the log stop.
- Journal retention was 46 MB (only ~2 boots kept) — yesterday's crash
  boots were vacuumed before investigation. **Raised to 512M
  (`SystemMaxUse=512M` in `/etc/systemd/journald.conf`) on 2026-09-02.**

## Next-occurrence checklist (do these, then report back)

1. Wait 2–3 min (not < 1) before hard-shutdown — rare hangs recover.
2. Try `Ctrl+Alt+F3` (TTY switch): if you get a login prompt the hang is
   display/compositor-level, not total.
3. Try SSH from the phone (tailscale is up; needs `sshd` enabled — not
   currently, see below).
4. Note: power source, whether a suspend/resume happened recently, what was
   running (games/browser/camera), and how the screen behaves.
5. **After the forced reboot, immediately** (before journal vacuum eats it):
   - `journalctl --list-boots`
   - `journalctl -b -1 -k | tail -100` (kernel messages of the dead boot)
   - `journalctl -b -1 -p 4 | tail -200`
   - save both, then report.

## Open threads / ideas

- Freezes were on 7.2.0; now running 7.2.2 — does the pattern continue?
  (Nothing in 7.2.0→7.2.2 touches GPU/scheduler; expected same.)
- 7.3-rc1 / 7.3 is the scheduled retest anyway (see `rdr2-proton-crash.md`
  watch list) — worth noting in any upstream report whether freezes
  persist there.
- If freezes continue: consider temporarily stopping `ipu7-camera-proxy`
  to rule the always-on 4K YUY2 gst pipeline in/out.
- Optional prep for better forensics: enable `sshd` so the SSH-from-phone
  test is possible, and consider kernel `hung_task`/`nmi_watchdog` — they
  only fire on soft lockups; a true hang usually still logs nothing.
