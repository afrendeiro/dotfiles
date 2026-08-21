# GPG key that owns the password store

Status: **working** (2026-08-21). The pass store is encrypted to the key
generated 2026-06-06; it was marked ultimately trusted to lift gpg's
"no assurance" refusal.

## The keys

- **Active store key** — `637A568B827E2775F1B99BF1022531B0D4D9FB15`
  (RSA 4096, created 2026-06-06, uid `Andre Rendeiro <afrendeiro@gmail.com>`),
  encryption subkey `E1B9E312338BC570`. Every entry in `~/.password-store`
  (311 files incl. `keypass2_database/`, `DeepSeek API`, `OeGMBT`,
  `disroot.org`) is encrypted to this subkey. Private key is in the local
  keyring and backed up on the USB stick
  (`gpg-private.key`, imported 2026-08-13 during the new-machine setup).
- **Old GitHub key** — `0AB3BF035B328B831BAF01B23388CF49452676D1`
  (RSA 3072, created 2020-04-28) — only its PUBLIC part exists (GitHub);
  no private key was found locally. It CANNOT decrypt any current store
  entry — do not attempt a `pass init` to it without the private key.

## The "no assurance" error (fixed)

`pass generate` failed with `gpg: There is no assurance this key belongs to
the named user` / `Unusable public key` because the June-6 key was newly
imported and its ownertrust was `unknown` — gpg refuses to encrypt to
untrusted keys. Fix (done):

```bash
printf 'trust\n5\ny\nquit\n' | gpg --batch --yes --command-fd 0 \
    --edit-key 637A568B827E2775F1B99BF1022531B0D4D9FB15
```

Verify: `gpg --list-keys` shows `[ultimate]` on the uid.

## Notes

- `.gpg-id` contains the email `afrendeiro@gmail.com`; gpg resolves it to
  whichever key carries that uid (currently the June-6 key).
- If the June-6 key is ever lost, the store is unrecoverable — the USB backup
  (`gpg-private.key`) is the only copy. Keep it safe.
