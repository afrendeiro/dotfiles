# Evolution + Microsoft 365 — stack record

Status: **Evolution adopted** (2026-08-21). EWS account bridge working:
mail + calendar + contacts + tasks all sync. Graph account configured but
awaiting CeMM admin consent. EWS hard deadline **2026-10-01**.

## Current stack

- **Client:** Evolution 3.60.2 + `evolution-ews` (CachyOS official repos).
- **Account "CeMM" (EWS type):** `outlook.office365.com` EWS, OAuth2 with
  Microsoft first-party client ID `d3590ed6-52b3-4102-aeff-aad2292ab01c`
  (preauthorized for the EWS resource — no admin approval needed), redirect
  `urn:ietf:wg:oauth:2.0:oob`.
- **OAuth tokens:** stored via libsecret → **gnome-keyring** (Secret
  Service). Prerequisite discovered the hard way: without a running Secret
  Service provider, sign-in fails ("OAuth2 secret not found" / "The name is
  not activatable"). gnome-keyring is autostarted via
  `hyprland/.config/autostart/gnome-keyring-secrets.desktop` (XDG
  autostart; Hyprland runs under UWSM).
  **Auto-unlock at login (2026-08-24):** `pam_gnome_keyring` added to
  `/etc/pam.d/greetd` (`-auth optional pam_gnome_keyring.so` +
  `-session optional pam_gnome_keyring.so auto_start`; backup
  `greetd.bak-20260824`). The `Default_keyring` password equals the login
  password, so PAM unlocks it at every login — no manual unlock. On the
  first reboot after the change a prompt still appeared; after ticking
  "automatically unlock" in the dialog it never prompts again. If the
  keyring ever needs a manual unlock, the prompt is now sticky/centered
  (`gcr-prompter` windowrule, `hyprland/.../autostart-user.lua`).
  Tokens are keyed `OAuth2::<Service>[<user>]` — NOT by source UID.
  Verify with: `secret-tool lookup e-source-uid 'OAuth2::Office365[arendeiro@cemm.at]'`
  (6158-byte payload confirmed 2026-08-21). If the first sign-in predates
  gnome-keyring, re-authenticate once so the store lands permanently.
- **Launch:** `SUPER+M` → Evolution (`launch-or-focus.sh`, class
  `org.gnome.Evolution`). OWA PWA keybinds (`SUPER+SHIFT+M`/C/T/SHIFT+T/N)
  kept as backup. In-app: Ctrl+1 Mail · Ctrl+2 Contacts · Ctrl+3 Calendar ·
  Ctrl+4 Tasks · Ctrl+5 Memos; File → New Window for a second view.
- **Thunderbird retired as primary 2026-08-21** — package kept installed
  for a few weeks as backup (`~/.thunderbird/` profile untouched). Do not
  plan around it.

## Why EWS for now, and the durable path

- EWS is blocked for Exchange Online on **2026-10-01**. The durable path is
  the **Microsoft 365 (Graph)** account type (evolution-ews `microsoft365`
  backend): mail + calendar + contacts + tasks.
- CeMM blocks user OAuth consent → the Graph account's app
  (`20460e5d-ce91-49af-a3a5-70b6be7486d1`, "GNOME Evolution") requires
  admin approval. Request auto-sent to IT 2026-08-21, **still pending**.
- The Graph account is preconfigured at
  `~/.config/evolution/sources/416f….source` (OverrideOauth2=false →
  GNOME's ID, nativeclient redirect). When IT approves: sign in to it once,
  then drop the EWS account.
- Graph account scopes requested (from evolution-ews source):
  Calendars.ReadWrite(.Shared), Contacts.ReadWrite(.Shared),
  Mail.ReadWrite(.Shared), Mail.Send(.Shared), MailboxSettings.Read,
  People.Read, Tasks.ReadWrite(.Shared), User.Read, User.ReadBasic.All,
  offline_access.

## Client-ID workarounds attempted 2026-08-21 — dead, do NOT retry

| Client ID | Result |
|---|---|
| `20460e5d-ce91-49af-a3a5-70b6be7486d1` (GNOME Evolution) | admin approval required — the pending IT request |
| `d3590ed6-52b3-4102-aeff-aad2292ab01c` (MS Office) | AADSTS65002 for Graph resource (first-party, not preauthorized) — fine for EWS only |
| `27922004-5251-4030-b22d-91ecd9a37ea4` (Outlook Mobile) | AADSTS65002 (same) |
| `de8bc8b5-d9f9-48b1-a8ad-b748da725064` (Graph Explorer) | preauthorized ✓, but SPA → AADSTS9002325: PKCE required; evolution-ews has **no PKCE support** (verified in source) |
| `d6d589a7-2886-418e-9407-53fac6e92415` (Mozilla) | AADSTS700016: app not in tenant |

Conclusion: no OAuth app ID gets into M365 without tenant admin approval.

## Rejected paths (do not revisit without new facts)

- **CalDAV/CardDAV for M365** — does not exist for business tenants
  (consumer Outlook.com only: `outlook.live.com/owa/…`; `outlook.office.com`
  returns 400; MS Q&A 2025-02-14 confirms no CardDAV).
- **M365-Calendar-for-Thunderbird add-on (kowjens)** — third-party Graph
  add-on; needs Entra app consent (same IT wall).
- **DavMail / TbSync bridges** — DavMail is EWS-based (dies 2026-10-01);
  TbSync providers unmaintained.
- **matcha / Mailspring / other Linux clients** — matcha trial abandoned
  when Evolution was adopted; Mailspring has no clean Arch install.

## TODO (future agent)

- When the IT approval lands: sign in to the Graph account, verify
  mail/calendar/contacts/tasks, remove the EWS account (or keep as
  fallback until Oct 1).
- Oct 1 2026: EWS account must be gone (blocked server-side anyway).
- Consider removing the Thunderbird package once the Graph account has been
  running for a while.
