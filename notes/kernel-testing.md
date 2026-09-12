# Testing a vanilla Arch kernel alongside CachyOS kernels

Status: procedure verified 2026-09-12 (installed `linux` 7.2.4-arch1-2 for the RDR2
regression A/B — see `rdr2-kernel-regression-report.md`).

Use when a bug must be classified as CachyOS-specific vs upstream/mainline.

## Install

```sh
pkexec pacman -S linux linux-headers
```

- `linux` is in Arch core (CachyOS repos sit on top of Arch) and installs
  alongside `linux-cachyos`/`linux-cachyos-lts` — nothing is replaced.
- `limine-mkinitcpio-hook` builds the initramfs and adds the entry to
  `/boot/limine.conf` automatically, using `KERNEL_CMDLINE[default]` from
  `/etc/default/limine` (same cmdline as the CachyOS entries).
- `/boot` needs room for one more kernel + initramfs (~150 MB + ~50 MB).

## Boot

- Reboot and select the `linux` entry in the limine menu. `BOOT_ORDER` in
  `/etc/default/limine` does **not** guarantee the new entry is default — pick it
  manually.
- Verify with `uname -r` (e.g. `7.2.4-arch1-2`).
- Keep the CachyOS/LTS entries as fallback: vanilla kernels **≤ 7.1.9 do not boot
  on this Panther Lake laptop** (black screen right after the bootloader); 7.2.4
  boots fine.

## Remove

```sh
pkexec pacman -Rns linux linux-headers
```

The hook removes the limine entry. Reboot to return to CachyOS.

## Notes

- `xe.enable_psr=0 xe.psr_safest_params=1` are in the shared cmdline, yet the
  `xe: *ERROR* Timed out waiting for PSR Idle` messages still appear on vanilla
  7.2.4 (see the RDR2 note).
- Proton games inherit the **Steam client's environment** — restart Steam with
  env vars to A/B them without touching launch options:
  `PROTON_NO_NTSYNC=1 setsid steam` (ntsync off) or
  `WINEDEBUG=+seh PROTON_LOG=1 setsid steam` (writes `~/steam-<appid>.log`).
  Restart Steam normally afterwards.
- `pkexec` auth needs the noctalia polkit prompt; if it hangs, check
  `journalctl -b -u polkit` — a failed prompt shows up as
  `pam_unix(polkit-1:auth): conversation failed`.
