# Camera (IPU7 + CVS) on Linux — how it works, and the two bugs

Status: working as of 2026-08-21. Camera streams to browsers/desktop apps via
libcamera → v4l2loopback relay.

Re-checked 2026-08-26: **no native solution; all workarounds still required** —
libcamera still 0.7.2-3.1 (soft-ISP stride crash present), no
`libcamera-provider.so` in `/usr/lib/spa-0.2/v4l2/`, and kernel 7.2.0-1-cachyos
still logs `intel-ipu7 ... Failed to get runtime PM` after s2idle (the
90-ipu7-power.rules workaround stays). Upstream: intel/vision-drivers#36 still
open; RH bug 2413656 still NEW — Hans de Goede has left IPU6/IPU7 work
(reassigned to Kate Hsuan, 2026-08-18), so upstreaming pace looks unchanged.

## Hardware

- XPS 14 (DA14260): IPU7 (PCI `8086:b05d`) + **OmniVision OV08X40** sensor
  (ACPI `OVTI08F4:00`) behind a **Synaptics SVP7500 CVS bridge**
  (USB `06cb:0701`, the "usbio" i2c buses `i2c-16/17` hang off it; the
  sensor is `ov08x40 17-0036` on `i2c-17`).
- No USB UVC camera: `lsusb` only shows the SVP7500 (06cb:0701), which is the
  CVS chip, not a fingerprint reader.
- Only `s2idle` suspend is available.

## Why the camera did not work at all

The sensor cannot enumerate until Intel's **out-of-tree `intel_cvs` driver**
(`intel/vision-drivers`) does a "transfer of ownership" handshake with the
SVP7500. Mainline has no such driver. Symptom: `OVTI08F4:00` exists as an
ACPI device but never gets an i2c client; the media graph has 32 IPU7 ISYS
capture nodes but no sensor entity; nothing in `lsusb` looks camera-like.

## The fix (3 parts)

1. **`intel_cvs`** — built from `intel/vision-drivers` via **DKMS**
   (sources in `/usr/src/vision-driver-1.0.0`, AUTOINSTALL → auto-rebuilds
   on kernel updates; module lands in
   `/usr/lib/modules/<ver>/updates/dkms/`). Autoloads via its ACPI aliases
   (`INTC10CF/DE/E0/E1/FA`). Installed by `setup-dotfiles.sh`.
2. **Load order** — `/etc/modprobe.d/ipu7-usbio-order.conf`
   (`softdep intel_ipu7 pre: usbio gpio_usbio i2c_usbio intel_cvs
   intel_skl_int3472_discrete`), tracked in
   `bootstrap/cachyos/modprobe.d/`.
3. **libcamera software ISP in CPU mode** —
   `/etc/libcamera/configuration.yaml`:
   ```yaml
   version: 1
   software_isp:
     mode: cpu
   ```
   Required because libcamera ≥ 0.7.2 requests an EGL input stride of 4096
   bytes that the ipu7 isys driver ignores (it delivers 3904). The soft ISP
   then reads misaligned rows → garbage pixel values → `SwStatsCpu` yHistogram
   OOB assert → crash ("std::array<unsigned int, 64> operator[]" in
   `libcamera::SwStatsCpu::processBayerFrame2`). The CPU debayer does not
   request a stride, so the driver's own is used and everything lines up.
   Tracked in `bootstrap/cachyos/libcamera/configuration.yaml`.
4. **Browser/desktop access** — v4l2loopback (`video_nr=33`,
   `card_label=IPU7-Camera`; options in
   `bootstrap/cachyos/modprobe.d/v4l2loopback.conf`) + user systemd service
   `systemd/.config/systemd/user/ipu7-camera-relay.service` running
   `gst-launch-1.0 libcamerasrc ! videoflip method=rotate-180 ! videoconvert
   ! video/x-raw,format=YUY2,width=3840,height=2160 ! v4l2sink
   device=/dev/video33`.
   The `videoflip rotate-180` matches the CachyOS guide for this XPS; remove
   if orientation is wrong.
5. **Privacy LED (proxy + on-demand relay)** — a black-frame proxy service
   `systemd/.config/systemd/user/ipu7-camera-proxy.service`
   (`videotestsrc pattern=black`, same 4K YUY2 caps as the relay, 30 fps,
   ~5 % CPU) ALWAYS writes to `/dev/video33`, so the loopback always has a
   producer attached: consumers can open + STREAMON without EIO/EBUSY, and
   the format AND frame rate they negotiate match what the relay delivers
   (4K YUY2 @ 30 fps), so the swap is seamless and browsers don't cap to a
   low fps. The watchdog `ipu7-camera-watch.service`
   (`scripts/.local/bin/ipu7-camera-watch.sh`, a /proc fd scan every 0.5 s —
   v4l2loopback ≥ 0.15 emits no open/close uevents) swaps the proxy for the
   real relay while any app STREAMS the device and swaps back after the
   device stays unread for 15 s, so the sensor (and its privacy LED) only
   runs while the camera is actually used. Consumers are detected by open
   flags: only O_RDWR/O_WRONLY holders count — Chromium's capture service
   keeps an O_RDONLY monitor fd open permanently and probe enumerations are
   O_RDONLY, so they never trigger or pin the relay. The proxy must be
   dropped BEFORE the relay starts: v4l2loopback lets only one output fd set
   the format (else the relay's S_FMT → EBUSY), and a brief producer-less
   gap only stalls the already-streaming consumer, never errors it.
   `exclusive_caps=1` is REQUIRED on the loopback: Chromium's V4L2 factory
   skips any device advertising both CAPTURE and OUTPUT caps (assumed
   memory-to-memory, crbug.com/139356) — without it Brave sees no cameras.
   With exclusive_caps the loopback advertises CAPTURE while a producer is
   attached (the proxy always streams, so it is always listable) and OUTPUT
   when idle; `keep_format=1` cannot be used instead (it makes QUERYCAP
   show CAPTURE even to the producers, so gst v4l2sink refuses to open as
   an output device). Known caveat: at 1080p/1440p relay caps the libcamera
   0.7.2 soft-ISP crashes (stride bug below); only 4K is stable — 4K@30
   works (~29 fps). The raw IPU7 ISYS nodes (/dev/video1-31) are also
   listed by the v4l2 camera provider (Firefox) but not by Chromium (bayer
   formats aren't in its usable list); selecting them fails ("Link has
   been severed").

## Secondary bug: IPU7 dies on suspend/resume

Staging `drivers/staging/media/ipu7/ipu7.c` `ipu7_resume()` fails at
`pm_runtime_resume_and_get(&isp->psys->auxdev.dev)` after s2idle
("Failed to get runtime PM" in journalctl); the driver swallows the error and
IPU7 stays down. Workaround: udev rule
`bootstrap/cachyos/udev/rules.d/90-ipu7-power.rules` keeps IPU7
runtime-active (`ATTR{power/control}="on"`). Upstream only has refcount-leak
fixes for this path (merged 2026-07-08, `b298b808`/`843644e1`; not in any
released kernel as of 7.1.8).

## Verify after boot

- `ls /sys/bus/i2c/devices/ | grep ovti` → `i2c-OVTI08F4:00`
- `media-ctl -d /dev/media0 -p | grep ov08` → `ov08x40 17-0036` entity
- `journalctl -k | grep -i "transfer of ownership"` → success line
- `systemctl --user status ipu7-camera-watch` → active (the proxy
  `ipu7-camera-proxy` is active when idle, the relay
  `ipu7-camera-relay` replaces it while an app uses the camera; idle LED is
  off because the proxy doesn't touch the sensor)
- `ffmpeg -f v4l2 -i /dev/video33 -frames:v 1 /tmp/cam.jpg` → real image
  (works straight from cold — the proxy keeps a producer attached)
- Direct stills: `cam --camera 1 --capture=1 --file=/tmp/cam.dng`

## References

- https://github.com/CachyOS/linux-cachyos/issues/804 (same platform guide)
- https://bugzilla.redhat.com/show_bug.cgi?id=2413656 (vision-drivers tracker)
- https://github.com/EliNaig/dell-pa14250-camera-fix (same SVP7500 hardware)
- https://github.com/intel/vision-drivers (intel_cvs source)

## For a future agent: track upstream progress / native solution

Status as of 2026-08-21: workaround in place; NO native (mainline) solution
exists. Periodically (e.g. after kernel/libcamera upgrades, or if this note is
> 2 months old) check whether the workaround can be removed:

1. **intel_cvs upstreaming** (the big one — camera will not enumerate at all
   without it):
   - https://github.com/intel/vision-drivers/issues/36 — request to upstream
     intel_cvs (its bulk-transfer code is the blocker)
   - https://bugzilla.redhat.com/show_bug.cgi?id=2413656 — Hans de Goede's
     tracker ("Intel vision drivers are missing...")
   - Fix test: unload intel_cvs, reboot, then check
     `ls /sys/bus/i2c/devices/ | grep -i ovti` → if `i2c-OVTI08F4:00`
     appears WITHOUT intel_cvs, mainline now handles the CVS handshake.
   - If upstreamed: remove the DKMS step from `setup-dotfiles.sh`, the
     `ipu7-usbio-order.conf` softdep can stay or go.

2. **libcamera 0.7.2+ soft-ISP crash** (reported as a regression here; NOT yet
   filed upstream by us):
   - Crash: `std::array<unsigned int, 64> operator[]` assert in
     `libcamera::SwStatsCpu::processBayerFrame2`; cause: libcamera requests a
     4096 B input stride ("Input buffer stride ignored by the driver.
     Requested 4096, got 3904") that the ipu7 isys driver ignores, so the
     stats walk reads misaligned rows.
   - Fix test: set `software_isp.mode: gpu` in `/etc/libcamera/configuration.yaml`
     (or delete the file) and re-run
     `gst-launch-1.0 libcamerasrc ! fakesink`. No crash + new libcamera
     version → regression fixed; then restore the default config and drop the
     cpu-mode file from `bootstrap/cachyos/libcamera/`.
   - If still broken and upstream is quiet, file it:
     https://gitlab.freedesktop.org/camera/libcamera/-/issues (component:
     software ISP / simple pipeline, mention ipu7 stride).

3. **ipu7 staging driver resume bug** ("Failed to get runtime PM"):
   - The refcount-leak fixes (`b298b808`, `843644e1`) are merged upstream but
     NOT the actual failure; check `journalctl -k | grep -i "runtime PM"`
     after a suspend/resume cycle on a newer kernel.
   - Fix test: delete `90-ipu7-power.rules` (or set
     `power/control` to auto) and suspend/resume; camera must still stream
     via the relay (`ffmpeg -f v4l2 -i /dev/video33 -frames:v 1 /tmp/t.jpg`).
   - Also relevant: https://github.com/intel/ipu7-drivers/issues/63 (PSYS
     permanently defers on in-tree kernels — hardware ISP; we use the CPU
     soft ISP so this is not blocking).

4. **On-demand relay is a stopgap** (v4l2loopback has no open/close uevents
   since 0.15; the /proc-scan watchdog + proxy swap in
   `ipu7-camera-watch.sh` is a hack):
   - If a future pipewire ships `libcamera-provider.so`
     (`ls /usr/lib/spa-0.2/v4l2/`) the browser portal can expose the camera
     natively and the loopback + proxy + relay + watchdog can all go away
     (LED then follows page usage exactly).
   - Or if v4l2loopback regains open/close uevents, replace the watchdog
     with udev RUN rules.

When ALL of the above are native/working, strip the workaround:
`setup-dotfiles.sh` camera section,
`bootstrap/cachyos/{udev,modprobe.d,modules-load.d,libcamera}`, the `systemd`
module's proxy + relay + watchdog units, and this note's workaround sections
(keep a short "resolved natively" paragraph), then update the AGENTS.md
entry.

