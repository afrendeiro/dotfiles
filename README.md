# Dotfiles

Personal configs, deployed with [GNU stow](https://www.gnu.org/software/stow/).

## Install

```bash
git clone https://github.com/afrendeiro/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow fish tmux git nvim alacritty kitty ghostty ipython
```

## Commands

```bash
stow fish               # deploy a module
stow -D fish            # remove symlinks
stow -R fish            # restow (re-link)
stow --adopt fish       # move existing ~/ files into the repo, then symlink
```

## Post-install

```bash
git clone git@github.com:afrendeiro/pass.git ~/.password-store
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# In tmux: prefix + I to install plugins
```

## Machine-specific Settings

Create `~/.config/fish/conf.d/local.fish` (gitignored) for SSH hosts, Bluetooth devices, etc. See `fish/.config/fish/conf.d/local.fish.example`.

## Bootstrap

Pre-install packages on a fresh machine:

```bash
# Arch/CachyOS
bash <(curl -fsSL https://raw.githubusercontent.com/afrendeiro/dotfiles/main/bootstrap/cachyos/install.sh)

# Ubuntu
bash <(curl -fsSL https://raw.githubusercontent.com/afrendeiro/dotfiles/main/bootstrap/ubuntu/install.sh)
```

## Structure

```
bootstrap/          OS-specific package install scripts
fish/               Fish shell config
tmux/               Tmux config with tpm plugins
git/                Git global config
nvim/               Neovim (LazyVim) config
alacritty/          Alacritty terminal config
kitty/              Kitty terminal config
ghostty/            Ghostty terminal config
ipython/            IPython startup scripts
legacy/             Deprecated configs kept for reference
```
