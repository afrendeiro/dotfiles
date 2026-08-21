# Camera (IPU7 + CVS) on Linux — how it works, and the two bugs

Status: working as of 2026-08-21. Camera streams to browsers/desktop apps via
libcamera → v4l2loopback relay.

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
   `card_label=IPU7-Camera`, `exclusive_caps=1`; options in
   `bootstrap/cachyos/modprobe.d/v4l2loopback.conf`) + user systemd service
   `systemd/.config/systemd/user/ipu7-camera-relay.service` running
   `gst-launch-1.0 libcamerasrc ! videoconvert ! videoflip method=rotate-180
   ! video/x-raw,format=YUY2 ! v4l2sink device=/dev/video33`.
   Tradeoffs: always-on while logged in (privacy LED on), ~CPU soft ISP.
   The `videoflip rotate-180` matches the CachyOS guide for this XPS; remove
   if orientation is wrong.

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
- `systemctl --user status ipu7-camera-relay` → active
- `ffmpeg -f v4l2 -i /dev/video33 -frames:v 1 /tmp/cam.jpg` → real image
- Direct stills: `cam --camera 1 --capture=1 --file=/tmp/cam.dng`

## References

- https://github.com/CachyOS/linux-cachyos/issues/804 (same platform guide)
- https://bugzilla.redhat.com/show_bug.cgi?id=2413656 (vision-drivers tracker)
- https://github.com/EliNaig/dell-pa14250-camera-fix (same SVP7500 hardware)
- https://github.com/intel/vision-drivers (intel_cvs source)
