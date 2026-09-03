# Remote herdr checks from the phone — tailscale + ssh (2026-09-03)

Purpose: occasionally check on herdr sessions from an Android phone
(Termux) over the tailnet — status peeks, transcript reads, and light
actions (send keys / prompt agents). No TUI attach for now.

## Setup (done 2026-09-03)

- **Tailscale**: `tailscale up --accept-dns=false` — node `afr` on the
  personal tailnet. The tailnet IP is stable (`tailscale ip -4` on the
  laptop; peers: the Android phone `pixel-7a`, a `jellyfin` host).
- **sshd**: openssh, `/etc/ssh/sshd_config.d/99-tailscale.conf`:
  `ListenAddress <tailnet-ip>` (the laptop's tailscale IP), `PasswordAuthentication no`,
  `KbdInteractiveAuthentication no`, `AllowUsers afr`; enabled +
  started; host keys auto-generated on first start.
- **ufw**: `allow in on tailscale0 to any port 22 proto tcp` (v4+v6) —
  ufw default is deny-incoming, so this rule is required.
- **Key**: phone ed25519 (`u0_a419@localhost`) in `~/.ssh/authorized_keys`
  with `no-agent-forwarding,no-port-forwarding,no-X11-forwarding,from="100.64.0.0/10"`
  (tailnet-only, no agent/port/X11 forwarding — note: do NOT use
  OpenSSH's blanket `restrict` option here, it also disables PTY
  allocation → "PTY allocation request failed on channel 0").

## ⚠️ CRITICAL quirk — never enable tailscale MagicDNS on this machine

`tailscale up` (defaults) enables MagicDNS, which expects systemd-resolved
to be authoritative. This machine's NetworkManager writes `/etc/resolv.conf`
directly (NM default, no `dns=` line), so the clash breaks **ALL DNS** —
symptom: no websites, DNS timeouts everywhere, even with tailscale
"working". Happened 2026-09-03; fix = `tailscale down` or
`tailscale up --accept-dns=false`. Always pass `--accept-dns=false`.
The tailscale health warnings ("systemd-resolved and NetworkManager wired
incorrectly", "accept-routes is false") are expected and harmless — we use
tailnet IPs, not MagicDNS. (Proper fix would be NM `dns=systemd-resolved`,
untried.)

## Phone usage (Termux)

```
ssh afr@<laptop-tailscale-ip>      # tailscale ip -4 on the laptop
herdr-status.sh            # one-screen summary: HOT (working/blocked) first
```

herdr CLI is fully headless over ssh (no HERDR_ENV needed; server socket
default `~/.config/herdr/herdr.sock`):

```
herdr agent list                     # all agents + idle/working/blocked
herdr agent get <pane-id>            # one agent (all agents are named
herdr agent read <pane-id> --lines 60     # opencode → target by PANE ID)
herdr agent send-keys <pane-id> ctrl+c    # interrupt
herdr agent prompt <pane-id> "..."        # submit input
herdr pane read <pane-id> --lines 60      # raw pane output
herdr pane run <pane-id> "cmd"            # run a command in a pane
```

Verified headless 2026-09-03: `status`, `pane list`, `agent list`,
`send-keys <pane> esc` all work with HERDR_ENV unset.

## Loose ends / future

- Phone→laptop ssh works (2026-09-03); first attempt hit the `restrict`
  PTY issue (fixed above) — retest interactive shell + `herdr-status.sh`.
- `herdr --remote <ssh-target>` exists for full remote TUI attach — would
  need the herdr binary in Termux; phone-TUI ergonomics are poor, v2 idea.
- Optional: MagicDNS fix via NM `dns=systemd-resolved` if hostname-based
  access is ever wanted (untried, re-test web carefully after).
- sshd/ufw config is machine-local (/etc) — not in dotfiles. The
  herdr-status.sh script IS committed (scripts module).
