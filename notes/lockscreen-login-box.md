# Noctalia lockscreen — login box centering (eDP-1)

Status: **fixed** (2026-08-20). Login box is dead-center on the laptop screen
(1920x1200, scale 1).

## Why it was off-center

The noctalia lockscreen login box is a **widget** (`type = "login_box"`, fixed
ID `lockscreen-login-box@<output>`). Its position comes from
`[lockscreen_widgets]` in `~/.local/state/noctalia/settings.toml` (machine
state — NOT in the repo, per-monitor).

Two separate causes were hit:

1. **Stale per-output entries.** settings.toml still carried login-box
   positions for three outputs (`DP-1`, `DP-6`, `eDP-1`) from an old
   2-external-monitor layout. Only eDP-1 is ever connected now. Stored
   `cx = 640` rendered the box left of center. Login boxes render from stored
   `cx`/`cy` even when `lockscreen_widgets.enabled = false` (they bypass the
   enabled check in the source); outputs without an entry get defaults.
   Fix: delete the stale section, restart the daemon — it re-creates the
   section with just the connected output at defaults.
2. **Default placement is bottom-anchored, not centered** (by design):
   `panelY = screenHeight - height - 84.0F` in
   `src/shell/lockscreen/lockscreen_login_box.cpp`. After fixing (1) the box
   was centered horizontally (cx = 960) but sat 84px off the bottom
   (cy = 1018). Fix: set `cy = 600`.

## Applied fix

In `~/.local/state/noctalia/settings.toml`:

```toml
[lockscreen_widgets.widget."lockscreen-login-box@eDP-1"]
box_height = 196.0
box_width = 810.0
cx = 960.0
cy = 600.0   # dead center of 1920x1200 (was 1018 = bottom-anchored default)
output = "eDP-1"
```

## Re-applying (e.g. after a noctalia settings reset)

1. Stop the daemon: `pgrep noctalia` → `kill <pid>` (it is a Hyprland child;
   restart manually, not via exec-once).
2. Edit `[lockscreen_widgets]` in `~/.local/state/noctalia/settings.toml`:
   set `cx = 960.0`, `cy = 600.0` on the eDP-1 login box (or delete the
   section for stock defaults).
3. Start: `setsid noctalia -d`.

Alternative (not used): drag the box in the editor
(`noctalia msg lockscreen-widgets-toggle-edit`).
