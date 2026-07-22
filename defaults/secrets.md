# Secrets and sensitive data

- Every repo gets a pre-commit hook that scans staged changes for
  credentials, key material, and PII before they can be committed. Use
  standard tooling — the pre-commit framework with the official gitleaks
  hook (extra rules via `.gitleaks.toml` `[extend]`) — not hand-rolled
  scanners. Set it up as part of the first substantial change.
- Layer the defenses; don't rely on any single one:
  - **pre-commit** — catches secrets before they enter history
  - **CI** — a secret scanner (e.g. the gitleaks action) on every push/PR
  - **platform** — GitHub secret scanning with push protection enabled in
    repo or org settings
- Never weaken or bypass these checks (`--no-verify`, editing patterns)
  without flagging it to me explicitly first.
- A false positive gets an explicit inline allow-marker, not a disabled
  check.
- If a real secret ever reaches history — even briefly, even in a private
  repo — treat it as compromised: rotate it and say so. Deleting the file
  or force-pushing does not un-leak it.
