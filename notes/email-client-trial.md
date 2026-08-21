# Email client trial — matcha (M365)

Status: **in progress** (2026-08-21). matcha 0.44.0 installed at
`~/.local/bin/matcha` (GitHub release, statically linked).

## Scope

Trial of a modern, open-source, Linux-first mail client for the **M365 work
account only** (no Posteo). Exchange calendar/contacts are deferred until the
mail client is settled.

## Context

- Thunderbird 153 in use; TB 154 adds native Graph (see
  `notes/thunderbird-m365-graph.md`) but feels bulky/dated.
- **Mailspring was dropped from the trial**: AUR is banned (AGENTS.md Safety),
  its official Linux builds are .deb/.rpm only, and it is NOT on Flathub — no
  clean install path on Arch.
- EWS is retired for Exchange Online on 2026-10-01; matcha uses IMAP+XOAUTH2,
  which is not being retired.

## Setup (matcha)

1. Binary: `matcha_0.44.0_linux_amd64.tar.gz` from GitHub releases →
   `~/.local/bin/matcha` (gitignored).
2. M365 account: IMAP `outlook.office365.com:993` + SMTP via XOAUTH2.
   matcha ships an OAuth helper (`config/oauth_script.py` in the repo):
   `oauth.py auth <email> --provider outlook` — browser flow, token refresh,
   tokens in `~/.config/matcha/oauth_tokens/`.
3. If the tenant blocks matcha's default client ID: reuse the Entra app
   registration pattern from `notes/teams-tui-go-azure-approval.md` (may hit
   the same IT-approval wall).
4. Run inside a herdr pane; daemon provides notifications.

## Success criteria

- Zero-friction M365 auth (or a documented workaround)
- Usable daily-driver: speed, notifications, read/write, attachments

## TODO (future agent)

Configure the M365 account in matcha (step 2 above), verify send/receive, and
record the result here. If the trial fails, reconsider TB 154 (Graph, native)
or the DavMail bridge (Graph mode) — see `notes/thunderbird-m365-graph.md`.
