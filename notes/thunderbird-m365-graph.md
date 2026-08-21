# Thunderbird + Microsoft 365 (Graph) — research & plan

Status: **planned, not implemented** (2026-08-21). No action taken yet.

## Context

- M365 work account (CeMM tenant) via Thunderbird 153.0.2.
- **EWS is retired for Exchange Online on 2026-10-01** — EWS-only clients
  (KMail, Evolution's main path, Owl add-on) are on borrowed time.

## Landscape (verified 2026-08-21)

- **Thunderbird 154.0 (2026-08-18): native Microsoft Graph for M365** — first
  open-source Linux client with Graph; EWS since 145 (Rust). This is the plan.
- Evolution 3.60: Graph in preview (m365 work items, behind a flag); EWS mature.
- KMail: EWS only, no shipped Graph.
- Hiri/Mailspring: closed source. Geary/Claws/Neomutt: IMAP only.

## Plan (when 154 lands in CachyOS repos)

1. `pacman -Syu` → Thunderbird 154
2. Re-provision the M365 account via the Graph flow (Thunderbird uses
   Microsoft's own Entra client ID — the tenant may need to allowlist it per
   Thunderbird's admin documentation)
3. Document the account setup in `docs/thunderbird.md`

## Dropped for now

- Reply/Reply All shortcut swap (was going to use tbkeys-lite 2.4.3, ATN
  add-on; JSON keymap `{"Ctrl+R": "cmd:cmd_replyall", "Ctrl+Shift+R":
  "cmd:cmd_reply"}` in the add-on prefs; works with TB 128–154).

## TODO (future agent)

Upgrade to TB 154 when packaged in CachyOS repos, convert the M365 account to
Graph, verify, and write `docs/thunderbird.md`.
