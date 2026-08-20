# teams-tui-go — Azure AD setup & IT approval follow-up

Status: **blocked on IT approval** (created 2026-08-20).

teams-tui-go (terminal TUI for Microsoft Teams, `~/.local/bin/teams-tui-go`,
launched with `SUPER+T`) authenticates via OAuth2 device code flow against the
Microsoft Graph API. The bundled Microsoft client ID is blocked by Microsoft
(`AADSTS65002` — first-party apps no longer preauthorized for Graph), so a
personal app registration was created. The device code sign-in now fails with
an IT-approval prompt; a tenant admin must approve the app.

## What already exists

Azure AD app registration in tenant `ca39edd1-7349-449a-bbae-314640be0def`
("Rendeiro Dev", CeMM):

- **Name:** `teams-tui-go`
- **Application (client) ID:** `24087451-19c7-4c30-ac3c-a67640afeaaa`
- **Sign-in audience:** any org directory + personal Microsoft accounts
- **Public client flow:** enabled (`isFallbackPublicClient`)
- **Delegated Graph permissions** (`requiredResourceAccess` on Microsoft Graph):
  - `offline_access`, `User.Read` (core auth/profile)
  - `Chat.Read`, `Chat.ReadWrite` (read/send chat messages)
  - `Files.Read`, `Files.ReadWrite` (attachment download/upload)
  - `Presence.Read.All` (user availability)
  - `User.ReadBasic.All` (sender profiles)
- Client ID set in `~/.config/teams-tui-go/config.json` (tracked in dotfiles —
  client IDs are public identifiers, not secrets).

## What IT needs to do

1. **Approve the app / grant consent** for the above delegated permissions.
   All are user-consentable (no admin consent *required* for these 8), but the
   tenant is blocking the consent — an admin must either:
   - approve the pending approval request for app
     `teams-tui-go` (`24087451-19c7-4c30-ac3c-a67640afeaaa`), or
   - enable user consent for this app via a consent policy / Conditional Access
     carve-out, or
   - in Azure portal → App registrations → `teams-tui-go` → API permissions →
     **Grant admin consent**.
2. If it was blocked by self-service registration instead: approve the app
   registration itself.
3. Optionally, if tenant CA blocks personal-account/multitenant apps: change
   the sign-in audience to single-tenant or add an exception.

**Not requested (do not grant unless asked):** `Team.*`/`ChannelMessage.*`
scopes (Teams channels need admin consent + are under development), `User.Read.All`.

## After approval

```bash
rm -f ~/.cache/teams-tui-go/token.json   # only if a partial token exists
teams-tui-go                             # complete device code flow
```

Expected error on failure: `AADSTS65001` (consent not granted) or a CA block
message — send the error code to IT as evidence.

## References

- Project: https://github.com/nospor/teams-tui-go (README + `AZURE_SETUP.md`)
- Local config: `teams-tui-go/.config/teams-tui-go/config.json` in dotfiles
