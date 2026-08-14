# Dotfiles

Personal configs, deployed with [GNU stow](https://www.gnu.org/software/stow/).

## Prerequisites

To recover this setup on a new machine, you must back up your SSH and GPG keys. Without them, nothing can be cloned or decrypted.

```bash
# Backup SSH and GPG keys to a USB stick
cp ~/.ssh/id_ed25519 /media/usb/
gpg --export-secret-keys --armor $(git config user.signingkey) > /media/usb/gpg-private.key
```

On a new machine, restore them:
```bash
cp /media/usb/id_ed25519 ~/.ssh/ && chmod 600 ~/.ssh/id_ed25519
gpg --import /media/usb/gpg-private.key
```

## Install

```bash
git clone git@github.com:afrendeiro/dotfiles.git ~/work/dotfiles
cd ~/work/dotfiles
# .stowrc sets --target=$HOME so plain `stow` works from any path
stow scripts fish tmux git nvim alacritty kitty ghostty ipython opencode
# On GNOME machines, also:
stow gnome
~/.config/gnome/load.sh
# On Hyprland machines, also:
stow hyprland
```

## Commands

```bash
stow fish               # deploy a module
stow -D fish            # remove symlinks
stow -R fish            # restow (re-link)
stow --adopt fish       # move existing ~/ files into the repo, then symlink
```

## Updating

Since configs are symlinked into the repo, editing a config file directly edits the repo copy. To push changes:

```bash
cd ~/work/dotfiles
git add <module>
git commit -m "<module>: description"
git push
```

## Post-install

```bash
git clone git@github.com:afrendeiro/pass.git ~/.password-store
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# In tmux: prefix + I to install plugins
```

## Machine-specific Settings

Create `~/.config/fish/conf.d/local.fish` (gitignored) for SSH hosts, Bluetooth devices, etc. See `fish/.config/fish/conf.d/local.fish.example`.

**Backup** the file encrypted via [pass](https://www.passwordstore.org/):

```bash
pass insert dotfiles/local.fish < ~/.config/fish/conf.d/local.fish
```

**Restore** on a new machine:

```bash
pass show dotfiles/local.fish > ~/.config/fish/conf.d/local.fish
```

## Bootstrap

Pre-install packages on a fresh machine:

```bash
# Arch/CachyOS
bash <(curl -fsSL https://raw.githubusercontent.com/afrendeiro/dotfiles/main/bootstrap/cachyos/install.sh)
# The base script detects the desktop environment and runs the matching
# bootstrap/cachyos/de/gnome.sh or de/hyprland.sh automatically.

# Ubuntu
bash <(curl -fsSL https://raw.githubusercontent.com/afrendeiro/dotfiles/main/bootstrap/ubuntu/install.sh)
```

## Structure

```
bootstrap/          OS-specific package install scripts (cachyos/ubuntu + common/)
bootstrap/cachyos/de/   Per-desktop-environment package scripts (gnome, hyprland)
scripts/            Helper scripts installed to ~/.local/bin/
gnome/              GNOME keybindings (dconf) — run ~/.config/gnome/load.sh to apply
hyprland/           Hyprland/noctalia changes from CachyOS defaults
fish/               Fish shell config
tmux/               Tmux config with tpm plugins
git/                Git global config
nvim/               Neovim (LazyVim) config
alacritty/          Alacritty terminal config
kitty/              Kitty terminal config
ghostty/            Ghostty terminal config
ipython/            IPython startup scripts
opencode/           Opencode (code assistant) skills and config
_legacy/            Deprecated configs kept for reference
```

## Per-DE modules

Only deviations from the distro defaults are tracked, so stock files stay untouched and receive updates.

- `gnome/` — dconf keybindings (dump/load via `~/.config/gnome/save.sh` / `load.sh`)
- `hyprland/` — Hyprland/noctalia changes. Generated monitor files from `nwg-displays`
  (`monitors.conf`, `monitors.lua`, `workspaces.conf`) are machine-specific and gitignored.
