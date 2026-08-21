# Automatic timezone (NM dispatcher IP geolocation)

Status: **working** (2026-08-21). System timezone auto-updates from IP
geolocation on network changes. Currently `Europe/Lisbon`.

## Why

The noctalia bar clock (`[widget.clock]` in the noctalia config) shows the
**system** timezone — it has no per-widget timezone option. The laptop travels
between Austria and Portugal; after a fresh CachyOS install the timezone was
still `Europe/Vienna`, so the panel clock was one hour off in Lisbon.

## How it works

`/etc/NetworkManager/dispatcher.d/90-auto-timezone` (root-owned, NOT in the
dotfiles repo — this note is the only record):

- Fires on `connectivity-change` / `up` / `vpn-up`.
- Geolocates via `https://ipinfo.io/timezone` (free tier, no key).
- Validates the result against `/usr/share/zoneinfo/`, then sets it only if it
  differs from the current timezone (`timedatectl set-timezone`).
- Exits silently on curl failure or invalid zone (keeps the last good zone).

Script content (for reinstall):

```bash
#!/bin/bash
export LC_ALL=C
interface="$1"; action="$2"
case "$action" in
    connectivity-change|up|vpn-up) ;;
    *) exit 0 ;;
esac
[ -n "$interface" ] || [ "$action" = "connectivity-change" ] || exit 0
tz="$(curl -fsS --max-time 5 https://ipinfo.io/timezone 2>/dev/null)"
[ -n "$tz" ] || exit 0
[ -f "/usr/share/zoneinfo/$tz" ] || exit 0
current="$(timedatectl show -p Timezone --value 2>/dev/null)"
if [ "$current" != "$tz" ]; then
    timedatectl set-timezone "$tz"
fi
exit 0
```

## Dead ends (do not re-debug)

- **`AutomaticTimeZone=yes` in `timesyncd.conf` does NOT exist.** systemd 261.2
  rejects it: `Unknown key 'AutomaticTimeZone' in section [Time], ignoring.`
  A drop-in was created and removed again (2026-08-21).
- **gnome-settings-daemon 50.1 has no geoclue plugin** (`pacman -Ql
  gnome-settings-daemon` lists no location module) — GNOME's automatic timezone
  only exists on full GNOME sessions anyway.
- **Noctalia's clock widget** supports only `color` + `format` — no timezone.
- `sudo` from a non-interactive shell can't read the password; use `pkexec`
  (noctalia's built-in polkit agent pops the GUI prompt) — see AGENTS.md.
  Note: `sudo -A` with the zenity ssh-askpass rejected the correct password;
  don't retry that path.

## Limitations

- Requires internet at the moment the network changes (offline → last zone
  kept).
- Country-level accuracy (ipinfo.io) — fine for Austria/Portugal.
- Depends on the free ipinfo.io service (≈50k requests/month; this fires only
  on network changes).
- **Noctalia caches the system timezone at daemon start.** The bar clock
  (`[widget.clock]`, no `timezone` key → "uses the system's local time" per
  the widget docs) keeps rendering the zone that was active when the daemon
  started. After any timezone change (manual or dispatcher), restart the
  daemon or the bar stays on the old zone — this is why the clock was still
  wrong after the first TZ fix (daemon had started while TZ was still
  Europe/Vienna).
  Restart procedure (noctalia is a Hyprland child; restart manually, not via
  exec-once):
  ```bash
  pkill -x noctalia && sleep 1 && setsid noctalia -d
  ```
  The dispatcher script does NOT restart noctalia — it runs as root and
  cannot cleanly respawn the user's session daemon.

## Reinstall (new machine / after system reset)

```bash
sudo install -D -m 755 - /etc/NetworkManager/dispatcher.d/90-auto-timezone <<'EOF'
<paste script from above>
EOF
```

Manual override anytime: `timedatectl set-timezone Europe/Lisbon`.

## TODO (future agent)

- `geoclue` was enabled (`systemctl enable --now geoclue`) during the failed
  systemd-automatic-timezone attempt; it is NOT needed by the dispatcher
  approach. Harmless, but consider disabling it.
