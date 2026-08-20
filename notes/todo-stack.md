# CalDAV task stack (Thunderbird + Tasks.org + Taskwarrior CLI)

Status: **planned, not implemented** (saved 2026-08-19, no time to set up yet).
All providers verified as current on 2026-08-19.

Goal: a to-do system that is as close to email as possible — tasks inside the
mail client (Thunderbird), email → task, standards-based (CalDAV, the IMAP of
tasks), colored priority tiers, quick drag reorder, open source, no server to
run. Posteo account (afrendeiro@posteo.net) already paid.

## Architecture

```
Taskwarrior CLI ──┐                     ┌── Thunderbird (email→task, colored categories)
                  ▼                     ▼
        Posteo CalDAV (posteo.de:8443, already paid)
                  ▲                     ▲
Tasks.org (Android, F-Droid) ───────────┘  (via DAVx5 or direct CalDAV)
```

## Key facts (verified 2026-08-19)

- Posteo supports CalDAV **tasks (VTODO)** on the server: "You can synchronise
  CalDAV tasks with other devices through DAVx5. It is not possible to display
  tasks in Posteo webmail." (server-side only — fine, UI is TB/Tasks.org/CLI).
- CalDAV endpoint: `https://posteo.de:8443`, username = full address
  `afrendeiro@posteo.net`, password = **app password** (Posteo has app
  passwords; required if 2FA enabled).
- **Fatto** (F-Droid, GPL-3.0, active 2026-07) = Taskwarrior 3.x Android client
  — rejected here only because it needs a self-hosted taskchampion-sync-server.
- Disroot was rejected as a host (removed from privacy lists; slow/verification
  heavy). Fruux rejected (user preference). PrivacyGuides only recommends E2EE
  calendars (Tuta/Proton) — neither is CalDAV, so not applicable to this stack.

## Manual setup (when implementing)

1. Posteo settings → Password and security: enable 2FA (TOTP) if not already;
   create an **app password** (e.g. "tasks-sync"). Store in pass, e.g.
   `pass insert posteo/app-tasks`.
2. Thunderbird: Calendar tab → New Calendar → **On the Network (CalDAV)** →
   `https://posteo.de:8443` → afrendeiro@posteo.net + app password. Tasks list
   appears in the Tasks tab. Set up colored categories (red=urgent, amber=next,
   blue=someday); drag an email onto the task pane to create a task.
3. Android: F-Droid → **Tasks.org** → CalDAV account (`https://posteo.de:8443`
   + app password) → colored lists/tags, drag order, reminders. Posteo's docs
   route through DAVx5; Tasks.org can also use DAVx5-managed accounts.

## Repo changes (when implementing)

- New stow module **`task/`**:
  - `task/.taskrc` — Taskwarrior config (colors, default project, reports)
  - `task/.config/systemd/user/task-sync.service` + `.timer` —
    `tw-caldav-sync -b tasks__all` every 10 min (`systemctl --user enable --now`)
- **README.md** + **AGENTS.md** — Tasks section (stack, app password in pass,
  syncall combination files contain no secrets).

## Install + first sync (when implementing)

- `sudo pacman -S task` (CachyOS)
- `uv tool install "syncall[tw,caldav]"` (matches uv workflow)
- First run:
  `tw-caldav-sync --caldav-calendar Tasks --caldav-url https://posteo.de:8443
  --caldav-user afrendeiro@posteo.net --caldav-passwd-cmd 'pass show posteo/app-tasks'
  --all -s tasks__all`
  (creates the saved combination in `~/.config/syncall/`, seeds both sides)
- Verify round-trip: add task in CLI → appears in Thunderbird + Tasks.org, and
  vice versa.

## Contingencies

- syncall README claims TW ≥ 2.6; if `tw-caldav-sync` breaks on Taskwarrior 3.x
  JSON export: fallback `pcaro90/twcaldav` (updated 2025-12) or drop the CLI
  layer (Thunderbird/Tasks.org unaffected either way).
- If Tasks.org direct CalDAV has trouble with Posteo: use the documented DAVx5
  path (F-Droid: `at.bitfire.davdroid`).

## Commits (when implementing)

- `task: add taskwarrior + syncall caldav sync stack`
- `docs: document posteo caldav task stack`

## TODO (future agent)

Implement the steps above. Manual setup items are the user's; everything else
(pacman install, uv tool install, task/ module, docs, systemd units, first
sync + verification) can be done from this repo.
