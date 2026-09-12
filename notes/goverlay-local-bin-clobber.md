# Goverlay's MAKO/lsfg frame-gen install clobbers the `~/.local/bin` stow symlink

Status: **workaround documented** (2026-09-12). Check after every goverlay frame-gen install.

## Symptom

After a `pacman -Suy` that upgraded **goverlay** (2026-09-12, update at 13:47), a
session of setting up frame generation in goverlay (14:03–14:05) broke unrelated
things:

- Every new fish shell: `source: Error encountered while sourcing file
  '/home/afr/.local/bin/env.fish': No such file or directory`
  (`fish/.config/fish/conf.d/uv.env.fish` sources it).
- Many Hyprland keybinds silently stopped working (every `binds.lua` entry that
  `exec`s `~/.local/bin/*.sh`: `toggle-wifi`, `toggle-bluetooth`, `toggle-dwt`,
  `toggle-edp`, `toggle-lid-suspend`, `toggle-tailscale`,
  `connect-sony-headphones`, `launch-or-focus`, `snapshot-*`).
- Launcher `/keys` (`SUPER+K`) broke: `keys.luau` hardcodes
  `/home/afr/.local/bin/keys-data.py`.
- All other repo scripts/binaries fell off PATH (`btop`, `herdr`, `uv`, `ruff`,
  `claude`, …).

## Root cause

`~/.local/bin` is a **stow directory symlink** to
`~/work/dotfiles/scripts/.local/bin`. Goverlay's frame-gen setup ran
`[MAKO-INSTALL] Installing MAKO Renderer in user space...` (journal 14:04:18)
which copied a prepared `.local` tree into `$HOME`, **replacing the symlink
with a real directory** containing only `lsfg-vk-cli` + `lsfg-vk-ui`.

Forensics: `~/.local/bin` had `mtime 2026-09-05` but `ctime 2026-09-12
14:04:19`, and the two binaries inside preserved their old mtimes — i.e. a
`cp -p`-style copy into a freshly created directory. `pacman` itself is
innocent; it only triggered the goverlay update that led to the install.

The mako-installer script (`scripts/.local/bin/mako-installer`) writes
individual files and normally goes *through* the symlink (that's why
`mako-*` binaries live in the repo dir); goverlay's own user-space install is
the one that replaces the symlink. Nothing under `~/.local/lib*` or
`~/.local/share` is stowed, so those are safe.

## Fix

```sh
# move whatever goverlay left behind into the repo dir
mv ~/.local/bin/* ~/work/dotfiles/scripts/.local/bin/
rmdir ~/.local/bin
cd ~/work/dotfiles && stow scripts
readlink ~/.local/bin   # must print ../work/dotfiles/scripts/.local/bin
```

Then verify: `ls ~/.local/bin | wc -l` (~53), `fish -c 'source
~/.local/bin/env.fish'`, `command -v keys-data.py toggle-wifi.sh`. No Hyprland
restart needed (binds resolve at keypress). `lsfg-vk-*` and `mako-*` are
gitignored under the "Tool binaries" section of `.gitignore`.

## Detection / prevention

After running goverlay's MAKO/lsfg install (or anything that installs frame-gen
in "user space"):

```sh
readlink ~/.local/bin   # a path pointing into work/dotfiles = healthy
```

If it's not a symlink, apply the fix above. The frame-gen install itself is
fine — only the symlink needs restoring.
