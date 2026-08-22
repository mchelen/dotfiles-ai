# Repo configuration as code

**Repository settings live in the repo as code, never clicked through the
UI.**

*GitHub-specific. The principle — settings as code, applied automatically, never clicked — carries to any forge; both implementations below are GitHub's.*

Settings that belong in code: description and homepage, feature toggles, merge
policy, Pages, vulnerability alerts, secret scanning and push protection, and
branch protection rules once they exist. When one must change, change the file
and let it apply — don't flip it in the UI and leave the code lying. If a UI
change already happened, reconcile the code to match (or revert) promptly.

Two implementations. Ask me which I want the first time a repo needs one,
rather than assuming:

## Terraform (default for repos I own alone)

- Official GitHub provider (`integrations/github`) with an `import` block to
  adopt the existing repo. Config lives in `infra/`.
- Apply in CI on merge to `main`, stateless: re-import, reconcile, discard
  state. No backend to run.
- The built-in Actions `GITHUB_TOKEN` cannot administer repo settings, so this
  needs a fine-grained PAT (Administration only, this repo only) as an Actions
  secret — and the workflow should skip with a notice when it's absent rather
  than failing.
- Never commit state, `*.tfvars`, or tokens.

## The Settings GitHub App (default when others can push)

- [`repository-settings/app`](https://github.com/repository-settings/app),
  hosted at `github.com/apps/settings`. Config lives in
  `.github/settings.yml` and syncs when pushed to the default branch.
- Sections are `repository`, `teams`, `collaborators`, `branches`,
  `environments`, `labels`, `milestones` — all optional. The `repository`
  section takes the familiar keys: `description`, `homepage`, `topics`,
  `has_issues`, `default_branch`, `allow_squash_merge`, `allow_merge_commit`,
  `allow_rebase_merge`, `delete_branch_on_merge`, `enable_vulnerability_alerts`.
- No PAT to mint or rotate, and settings changes arrive as reviewable pull
  requests like any other diff.
- **Know the trade before choosing it.** The app's own documentation warns that
  it "inherently escalates anyone with `push` permissions to the **admin**
  role", because pushing config to the default branch is enough to change
  settings. Mitigate it the way the docs prescribe: make an admin the
  `CODEOWNERS` owner of `.github/settings.yml` and require code-owner review.
  If that mitigation isn't in place, prefer Terraform.

## Setting this up on a repo for the first time

Both options need a one-time human step that an assistant cannot do: creating a
PAT, or installing a GitHub App. Don't stall silently on it and don't pretend
it's done — **write out the exact steps and say what you'll do once it's
finished.**

- **Terraform:** create a fine-grained PAT scoped to that repo with
  Administration read & write, save it as the `REPO_ADMIN_TOKEN` Actions
  secret, then say which workflow will pick it up. Name any additional
  permission the config needs — Pages settings need their own.
- **Settings app:** install `github.com/apps/settings` on the repo or org and
  grant it access to that repo, then say that the next push of
  `.github/settings.yml` to the default branch will apply. Mention the
  CODEOWNERS mitigation in the same breath, not later.

Then check it actually worked: read the settings back and compare against the
file. A workflow that skipped, a token missing a scope, or an app without
access all look identical to success from the outside — which is how a repo
ends up with settings-as-documentation instead of settings-as-code.

## Org-owned repos

Prefer the org's existing mechanism if there is one — `safe-settings`, an infra
monorepo, whatever it already runs — over introducing a second, per-repo way of
doing the same thing.
