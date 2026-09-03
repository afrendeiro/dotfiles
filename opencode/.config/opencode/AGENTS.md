# Global rules — afr's laptop

This machine is a Dell XPS 14 DA14260 running CachyOS. Full environment
documentation (desktop stack, configs, quirks) lives in the dotfiles repo.

## Hardware
- Laptop: Dell XPS 14 DA14260 (hostname `afr`), CachyOS, kernel 7.2.2-1-cachyos
- CPU: Intel Core Ultra X7 358H (16 cores, up to 4.8 GHz)
- GPU: integrated Intel Panther Lake Arc B390
- RAM: 30 GiB · Storage: 1.9 TB SK hynix NVMe SSD (zram swap)
- Machine-specific issues are tracked in `~/work/dotfiles/notes/`
  (e.g. EC hard-reset issue `xps14-da14260-hard-reset.md`, IPU7 camera
  `camera-ipu7.md`)

## Root commands
- `sudo` fails from a non-interactive shell (no TTY for the password prompt).
  Use `pkexec <cmd>` instead — it pops a GUI polkit prompt on the desktop
  and works from this session.

## Dotfiles
- `~/work/dotfiles` is a GNU stow repo whose own `AGENTS.md` documents the
  desktop stack (Hyprland/noctalia/herdr), the stow modules, and safety rules
  (no AUR, no secrets, etc.). Read it before touching any config.

## Known issues — check for fixes at the end of a task (PRIMARY agent only)
- This duty belongs exclusively to the top-level agent the user talks to
  directly (primary agents: build, plan, ...). **Subagents — agents launched
  via the Task tool (explore, general, scout, ...) — must SKIP this entire
  section**: no upstream-thread checks, no fetches for these issues, no
  note updates. The primary agent handles it.
- Primary agent: when finishing any task, briefly check whether upstream
  solutions have appeared for this laptop's two unresolved hardware issues
  (tracked in `~/work/dotfiles/notes/`):
  - XPS 14 DA14260 EC hard-reset/power-loss bug (`xps14-da14260-hard-reset.md`)
  - IPU7 camera (OV08X40) workaround stack (`camera-ipu7.md`)
- If a fix exists, summarize it to the user and update the relevant note;
  otherwise just report that they remain unresolved.
