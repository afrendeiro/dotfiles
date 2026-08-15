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
  post_hook reload). Edit the template, never `~/.config/herdr/config.toml`.
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
