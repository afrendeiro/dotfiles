# XPS 14 DA14260 — abrupt power loss on battery (EC hard reset)

Status: **unresolved** (last checked 2026-08-26). Watching the linked threads for a fix.

## Symptom

While running on battery (not AC), the built-in keyboard and/or trackpad stop
responding, then a few seconds later the machine instantly powers off — no clean
shutdown, no kernel panic, nothing in the journal. On the next boot the power
button blinks **1 amber + 6 white** and the BIOS logs a **"WDT"** event. Battery
health, temps, and every Dell diagnostic pass.

This machine (Dell XPS 14 DA14260, Panther Lake / Core Ultra X7) is affected.

## Diagnosis

- Dell service manual: **1 amber + 6 white = "generic catch-all for ungraceful EC
  (embedded-controller) code-flow error"** — the EC cuts power. Not an OS/kernel
  crash (journal ends abruptly with no shutdown sequence; `last -x` shows the
  boot as still-running).
- Firmware does **not** fix it: BIOS **1.9.0** (2026-07-10) still exhibits the bug.
  1.9.0 is only published as a Windows `.exe` on Dell's site (not on LVFS), so
  `fwupdmgr` correctly reports "no updates" on this machine.

## Current community state

- Promising DIY fix: insulating (Kapton) tape applied to the underside of the
  palm rest over the battery-power / palmrest-connector components. Reporter hit
  a 14-day crash-free milestone (2026-08-16) — unconfirmed long-term.
- Easier workaround reported by one user: run the **"Optimized"** power profile
  instead of "Quiet".
- Official path: contact Dell support, reference **KB 000455608** (Dell community manager
  pinned this on 2026-08-11; no official fix announced).
- omarchy #5953 was **closed** by its reporter (claimed a firmware update fixed it), but
  Dell-thread users call that premature — crashes on BIOS 1.9.0 continued into August
  (incl. Fedora). No BIOS > 1.9.0 exists and 1.9.0 is Windows-only (not on LVFS); this
  machine is still on 1.8.2.
- 2026-08-26 check: no solution, no recall, no BIOS update. Dell thread's OP shipped the
  laptop to Dell's service center; no verdict posted.

## Threads to check for a fix

- Dell community: https://www.dell.com/community/en/conversations/xps/xps-1416-2026-abrupt-crashshutdown-while-on-battery-da14260-da16260/6a41380230ba7b5c1c724a29
- Kapton-fix comment: https://www.dell.com/community/en/conversations/xps/xps-1416-2026-abrupt-crashshutdown-while-on-battery-da14260-da16260/6a41380230ba7b5c1c724a29?commentId=6a81fbd4cf4f0dc7850b0a12
- omarchy issue: https://github.com/basecamp/omarchy/issues/5953
- Reddit: https://www.reddit.com/r/DellXPS/comments/1skt8ct/dell_xps_16_2026_keeps_crashing_on_me/
- Reddit: https://www.reddit.com/r/DellXPS/comments/1tdvi4y/new_xps_14_da14260_randomly_loses_power/

## TODO (future agent)

Check the threads above for a confirmed or official fix (a BIOS > 1.9.0 that
addresses the EC power-loss, or a Dell recall/replacement program). If one lands,
update this note and remove this TODO.
