# notes/ — machine & environment knowledge

This directory holds durable knowledge about **this machine and its setup**:
hardware quirks, incidents, one-off fixes, and agreed-but-unimplemented plans.
It serves humans and agents alike and is read **on demand** — nothing here is
loaded into every agent session.

## Why document here

- **Hardware/environment quirks that masquerade as config bugs** — e.g. the EC
  power-loss issue (`xps14-da14260-hard-reset.md`) or the off-center
  lockscreen (`lockscreen-login-box.md`). Captured once so nobody re-debugs
  them or "fixes" a non-bug.
- **Machine-local fixes that live outside the repo** — state dirs like
  `~/.local/state/noctalia/` are not tracked; a note is the only record.
- **Plans** — agreed work that isn't implemented yet (`camera-ipu7.md`).

## Where things go (keep redundancy low)

| Location | Audience | What belongs there | When it's read |
|---|---|---|---|
| `AGENTS.md` | agents | **Constraints** & "do NOT" rules needed to edit this repo safely (feedback loops, generated files, symlink traps) | every session |
| `docs/` | humans | **Evergreen how-to**: stable usage guides for what's configured (keybinds, workflows) — no status lines, won't go stale | on demand |
| `notes/` | humans + agents | **Transient machine state**: quirks, incidents, one-off fixes, open plans — Status lines + dates | on demand |
| `README.md` | humans | Install/deploy overview of the whole repo | new machine / curious |

Rules of thumb:

- Will editing code or config **silently break something** without this
  knowledge? → `AGENTS.md`.
- **Stable how-to** on using the setup? → `docs/`.
- **Status line or a date** — it's about this machine, an incident, or open
  work, and will go stale? → `notes/`.
- **Prefer a one-line pointer over a restatement.** AGENTS.md/docs may point
  at a note (`docs/desktop-stack.md`, `notes/xps14-...`) instead of
  duplicating its content. If something appears in AGENTS.md it must be
  *acted on*; if it's in notes/ it's *context*.

## File conventions

- One topic per file, one file per topic.
- First lines: `# <topic>` followed by a `Status:` line (e.g. `fixed 2026-08-20`,
  `unresolved (last checked ...)`, `planned, not implemented`).
- End with a `## TODO (future agent)` section when follow-up work exists
  (the xps and camera notes use this).
- Link related notes and docs rather than copying their content.
