# Thunderbird + Microsoft 365 (Graph) — research & plan

Status: **decision made 2026-08-21** — interim: keep TB IMAP mail + Outlook
Web for calendar/contacts. Revisit when Thunderbird ships native Graph
calendar + address book (active roadmap item, no ETA).

## Context

- M365 work account (CeMM tenant) via Thunderbird 153.0.2.
- **EWS is retired for Exchange Online on 2026-10-01** — EWS-only clients
  (KMail, Evolution's main path, Owl add-on) are on borrowed time. IMAP is
  NOT affected; the current TB IMAP account (outlook.office365.com, OAuth2
  with Mozilla's client ID `d6d589a7-…`, already consented by the tenant)
  keeps working indefinitely.

## Key facts (verified 2026-08-21)

- **Thunderbird Graph support = mail only** (MozillaWiki, 2026-07-02;
  desktop roadmap 2026-07-23: "Active — Exchange (EWS, GraphAPI): *finalize
  … including calendar and address book support*" — not shipped, no ETA).
- **M365 business calendars/contacts cannot be used in Thunderbird without
  Graph.** CalDAV/CardDAV exists only for consumer Outlook.com
  (`outlook.live.com/owa/calendar/<email>/caldav/`), NOT for Exchange
  Online: `outlook.office.com/owa/calendar/<email>/caldav/` returns HTTP 400
  on all methods (a real CalDAV endpoint would 401 + WWW-Authenticate), the
  TB "Add calendar" wizard finds nothing there, and Microsoft Q&A
  (learn.microsoft.com, 2025-02-14) confirms no CardDAV for Exchange Online.
  Do not retry this path.
- TB 154.0 (2026-08-18) adds native Graph for M365 **mail** — optional for
  us (IMAP already works); the 154 upgrade itself is still worth doing.
- Evolution 3.60: Graph in preview (m365 work items, behind a flag); EWS
  mature. KMail: EWS only, no shipped Graph.

## Chosen interim (2026-08-21)

- Mail: stay on TB IMAP (no action).
- Calendar/contacts: Outlook Web. There is a Brave webapp shortcut for the
  OWA calendar, but it re-prompts for 2FA auth regularly (annoying) — that
  is the known cost of this interim.

## Rejected paths (do not revisit without new facts)

- **CalDAV/CardDAV for M365** — does not exist (see above).
- **M365-Calendar-for-Thunderbird add-on (kowjens)** — third-party Graph
  add-on; needs Entra admin consent, and CeMM IT is done with custom
  requests.
- **DavMail / TbSync bridges** — DavMail is EWS-based (dies 2026-10-01);
  TbSync providers unmaintained.

## Future plan (when TB ships native Graph calendar + address book)

1. `pacman -Syu` → TB with Graph calendar/address book (also picks up 154+).
2. Re-provision the M365 account via AccountHub → Graph flow (TB uses its
   own Entra client ID; the tenant already consents to it for IMAP, so it
   should work without IT).
3. Verify calendar + contacts sync; then document in `docs/thunderbird.md`.
4. Optionally also move mail to Graph at that point (feature parity, filters).

## Dropped for now

- Reply/Reply All shortcut swap (was going to use tbkeys-lite 2.4.3, ATN
  add-on; JSON keymap `{"Ctrl+R": "cmd:cmd_replyall", "Ctrl+Shift+R":
  "cmd:cmd_reply"}` in the add-on prefs; works with TB 128–154).

## TODO (future agent)

When TB's Graph calendar/address-book support ships (roadmap "Active"),
run the future plan above and write `docs/thunderbird.md`.
