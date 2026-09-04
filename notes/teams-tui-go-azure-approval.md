# teams-tui-go — Azure AD setup & IT approval follow-up

Status: **base scopes granted and working** (2026-09-04). Chats, files,
presence, and basic profiles verified. Optional features (extended
profiles, Teams channels, channel mentions) are OFF — they need separate
admin consent; see "Future" below.

teams-tui-go (terminal TUI for Microsoft Teams, `~/.local/bin/teams-tui-go`,
launched with `SUPER+T`, open-or-focus) authenticates via OAuth2 device
code flow against the Microsoft Graph API. The bundled Microsoft client ID
is blocked by Microsoft (`AADSTS65002` — first-party apps no longer
preauthorized for Graph), so a personal app registration was created.

## App registration

Azure AD app registration in tenant `ca39edd1-7349-449a-bbae-314640be0def`
("Rendeiro Dev", CeMM):

- **Name:** `teams-tui-go`
- **Application (client) ID:** `24087451-19c7-4c30-ac3c-a67640afeaaa`
- **Sign-in audience:** any org directory + personal Microsoft accounts
- **Public client flow:** enabled (`isFallbackPublicClient`)
- **Approved delegated Graph permissions** (granted by CeMM IT 2026-09-04):
  - `offline_access`, `User.Read` (core auth/profile)
  - `Chat.Read`, `Chat.ReadWrite` (read/send chat messages)
  - `Files.Read`, `Files.ReadWrite` (attachment download/upload)
  - `Presence.Read.All` (user availability)
  - `User.ReadBasic.All` (sender profiles)
- Client ID set in `~/.config/teams-tui-go/config.json` (tracked in dotfiles —
  client IDs are public identifiers, not secrets).

## Scope experiments 2026-09-04 — reverted

Enabling `user_profile_extended` / `teams_channels_enabled` /
`channel_mentions_enabled` makes the device-code flow request scopes OUTSIDE
the approved set → the IT-approval prompt reappears (expected; consent is
per-permission). All three were reverted to `false`; token deleted and
re-authenticated cleanly with the approved base set.

## Future: Teams channels in the TUI

Only if channel workflows in the TUI are wanted (channels currently live in
the Teams PWA, `SUPER+SHIFT+T`). Upstream marks the channel feature "under
development still". IT ask: Azure → app `teams-tui-go`
(`24087451-19c7-4c30-ac3c-a67640afeaaa`) → API permissions → add
**delegated** `Team.ReadBasic.All`, `Channel.ReadBasic.All`,
`ChannelMessage.Read.All` (+ optionally `ChannelMessage.Send`,
`ChannelMessage.ReadWrite`, `TeamMember.Read.All`) → **Grant admin
consent**. Then flip the flags, `rm ~/.cache/teams-tui-go/token.json`, and
re-authenticate.

## Re-authentication after scope/config changes

```bash
rm -f ~/.cache/teams-tui-go/token.json
teams-tui-go        # complete device code flow
```

Expected error on failure: `AADSTS65001` (consent not granted) or a CA block
message — send the error code to IT as evidence.

## References

- Project: https://github.com/nospor/teams-tui-go (README + `AZURE_SETUP.md`)
- Local config: `teams-tui-go/.config/teams-tui-go/config.json` in dotfiles
