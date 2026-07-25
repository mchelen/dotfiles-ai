# Repo configuration as code

- GitHub repository settings are managed declaratively, not clicked through
  the web UI. Use the official Terraform GitHub provider
  (`integrations/github`) with an `import` block to adopt the existing
  repo; keep the config in `infra/` in the repo itself.
- Settings that belong in code: description/homepage, feature toggles,
  merge policy, Pages, vulnerability alerts, secret scanning + push
  protection, and branch protection rules once they exist.
- Never commit Terraform state, lock-in tokens, or `*.tfvars` — state
  stays local (or in a proper backend), auth comes from the environment
  (e.g. `GITHUB_TOKEN=$(gh auth token)`).
- Prefer applying in CI on merge to main: a workflow runs the apply using
  the stateless import-block pattern (re-adopt, reconcile, discard state).
  The built-in Actions `GITHUB_TOKEN` cannot administer repo settings, so
  use a least-privilege fine-grained PAT (Administration only, this repo
  only) stored as an Actions secret — and skip gracefully when it's absent.
- When something must change in repo settings, change the `.tf` file and
  apply — don't flip it in the UI and let the code drift. If a UI change
  already happened, reconcile the code to match (or revert) promptly.
- For org-owned repos, prefer the org's existing mechanism if one exists
  (e.g. safe-settings, an infra monorepo) over per-repo Terraform.
