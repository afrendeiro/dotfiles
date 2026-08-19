# AGENTS.md

GNU stow dotfiles for a CachyOS laptop running Hyprland + noctalia + herdr.
Every top-level directory is a stow package whose internal path mirrors $HOME
(e.g. `fish/.config/fish/config.fish` → `~/.config/fish/config.fish`).
`.stowrc` sets `--target=$HOME`, so plain `stow <module>` works from repo root.

## Core workflow

- Configs are symlinked into $HOME — editing a file in place edits this repo.
- Deploy: `stow <module>` · remove: `stow -D <module>` · re-link: `stow -R <module>`
  · take over an existing ~/ file: `stow --adopt <module>`.
- `setup-dotfiles.sh` is the idempotent bootstrap (adopt + restore tracked files,
  then apply the detected DE module). Update it if the module set or stow
  behavior changes.
- New config → create `<module>/.config/...` under a new or existing top-level dir.
- Running `sudo` from a non-interactive shell fails (no TTY to read the password).
  Use `pkexec <cmd>` instead — it pops a GUI polkit prompt on the desktop and
  works from this session.

## Desktop stack (CachyOS + Hyprland + noctalia + herdr)

- Only deviations from CachyOS defaults are tracked. `hyprland.lua` `require`s
  `config.animations|autostart|colors|decorations|environment|inputs|misc|windowrules`
  — these are CachyOS-provided and NOT in the repo. Do not add or track them.
- Tracked Hyprland files live under `hyprland/.config/hypr/`:
  `config/variables.lua` (app vars, MONITOR1/2, NUM_WPM, find_external()),
  `config/binds.lua` (SUPER keybinds, uwsm launch prefix, noctalia msg panels),
  `config/monitors.lua` (eDP-1 modeline + external auto-right),
  `config/workspaces.lua` (10 persistent + gaming, on PRIMARY_MONITOR),
  `config/lid.lua` (must load AFTER monitor rules), and `hyprland.lua`.
- noctalia drives the bar/shell/theme. Binds use `noctalia msg <cmd>`; theme
  applies via `require("noctalia").apply_theme()` and `hooks.colors_changed`
  triggers `hyprctl reload`. Do NOT add `noctalia msg templates-apply` to
  `colors_changed` — noctalia re-renders user templates (incl. herdr's
  post_hook reload) automatically on palette change, so adding it creates a
  `colors_changed` ↔ `templates-apply` feedback loop (herdr "reloaded config"
  spam every ~1s).
- herdr's config is GENERATED from a noctalia template
  (`herdr/.config/noctalia/templates/herdr.toml` + `herdr-templates.toml`,
  post_hook reload). Edit the template, never `~/.config/herdr/config.toml`;
  apply with `noctalia msg templates-apply`.
  `panel_bg = "reset"` makes herdr inherit the host terminal's background
  instead of painting an opaque palette color — required for herdr panes
  (incl. opencode) to keep alacritty's transparency (`opacity = 0.6`).
- nwg-displays output (`monitors.conf`, `monitors.lua`, `workspaces.conf` at the
  hypr root, not under `config/`) is machine-specific and gitignored.
- noctalia `[shell.greeter_sync] privilege_command = "pkexec"` — the login-greeter
  sync elevates via the narrow `org.noctalia.greeter.apply-appearance` polkit
  action. This DEPENDS on a system polkit rule at
  `/etc/polkit-1/rules.d/49-noctalia-greeter.rules` (grants that action to
  `wheel`; see README "Greeter sync"). The default `run0` escalator uses the
  broad `org.freedesktop.systemd1.manage-units` action and prompts for a password
  on every wallpaper change — don't switch back to `run0` without also handling that.
- `[wallpaper] directory` points at `~/Pictures/wallpapers/omarchy` — a local,
  untracked folder. Wallpapers are the omarchy v4.0 `themes/*/backgrounds/` set,
  flattened as `<theme>__<file>`.

## Safety

- Never commit secrets: `.ssh/`, `*.local.fish`, `local.fish`, `fish_variables`,
  `.boto`, password store, nwg-displays monitor files are gitignored.
- Machine-specific settings belong in `~/.config/fish/conf.d/local.fish`
  (gitignored, backed up via pass) — see `fish/.config/fish/conf.d/local.fish.example`.
- Don't commit generated state: `lazy-lock.json`, `node_modules/`, `package*.json`,
  `plugins/`, `themes/`, and `btop|herdr|uv|uvx|llm` binaries. If `git status`
  shows surprises, check `.gitignore`.

## Commits

- Format: `module: description` (e.g. `fish: remove auto tmux attach on login`).
  Commit per module where practical. Branch is `main`.

## opencode module

- `opencode/.config/opencode/skills/*/SKILL.md` + `opencode.jsonc` are stowed into
  `~/.config/opencode/`. Editing a skill here edits the deployed copy — keep
  changes consistent with the coding-style conventions.

## nautilus module

- `nautilus/.local/share/nautilus-python/extensions/open-terminal.py` adds
  "Open Terminal Here" to the nautilus context menu (folder + background).
  Requires the `nautilus-python` package (installed by `bootstrap/cachyos/install.sh`).
  After changing the script, restart nautilus (`nautilus -q`) to reload it.
  It launches `kitty -d <path>` — update the `TERMINAL` constant if the main
  terminal changes (mirror `hyprland/.../variables.lua`).

## alacritty module

- Deployed on this machine (NOT left to stock presets). `alacritty.toml`
  imports the noctalia-generated theme `~/.config/alacritty/themes/noctalia.toml`
  (generated, NOT in the repo) and sets `opacity = 0.6` to match kitty's
  `background_opacity 0.6` — keep transparency in sync across terminals.
  `live_config_reload = true`, so edits apply to running windows.
- Host terminal for herdr (`alacritty --class herdr -e herdr`) and the tmux
  session (`alacritty --class tmux ...`) via `hyprland/.../variables.lua`.
  Do NOT add color overrides that shadow the imported noctalia theme.

## Hardware notes

- `notes/xps14-da14260-hard-reset.md` — known EC power-loss/hard-reset issue on
  this laptop (XPS 14 DA14260): on battery the keyboard/trackpad freeze, then the
  EC cuts power (1 amber + 6 white blink code, BIOS "WDT" event). Unresolved as of
  2026-08-18; before assuming any abrupt shutdown is a config problem, check the
  Dell/omarchy threads linked in that note for a fix.
