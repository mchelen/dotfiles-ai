<!-- BEGIN dotfiles-ai (managed block, edit in the dotfiles-ai repo) -->
# Architecture documentation

**Every project keeps an `ARCHITECTURE.md`, updated in the same change that
rewires a component.**

- Every project keeps an `ARCHITECTURE.md` at the repo root: a high-level
  description of the code — major components, how they fit together, and key
  data flows — including Mermaid diagrams for structure and flows.
- Keep it current: when a change adds, removes, or rewires a component,
  update `ARCHITECTURE.md` in the same change. If it doesn't exist yet,
  create it as part of the first substantial change.
- Stay high level: components and boundaries, not function-by-function
  detail. If the diagram needs updating for small edits, it's too detailed.

# Code style

**Match the surrounding code, make the smallest change that solves the problem,
and never add a dependency without saying why.**

- Match the existing style of the codebase over any personal or general default.
- Prefer the smallest change that solves the problem; avoid opportunistic
  refactors unless I ask.
- Don't add comments that narrate what the code does; comment only non-obvious
  constraints or reasoning.
- Don't add new dependencies for something a few lines of code can do.
  If a dependency is genuinely warranted, say so and why before adding it.

# Communication

**Lead with the answer, say so before doing something you think is a bad idea,
and disclose whatever you skipped or left failing.**

- Lead with the answer or outcome, then supporting detail.
- If something I asked for seems like a bad idea, say so before doing it —
  a one-line "heads up, X might be better because Y" is enough.
- When you're unsure about intent, ask one focused question rather than
  guessing and building the wrong thing.
- Tell me what you *didn't* do: skipped steps, failing tests, known gaps.
  Don't present partially working results as done.

# Offloading mechanical work

**Mechanical work belongs in a command, not in your context.**

When a shell
command, script, or CI job produces the same answer, run it instead of loading
the material and working it out yourself — it's cheaper, it's reproducible, and
it leaves context for the parts that actually need thought.

- **Query, don't read.** Search, filter, count, and compare with the tools built
  for it — `grep`, `jq`, `diff`, `wc` — rather than reading a large file or a
  large command output to find a small part of it.
- **Ask for the answer, not the transcript.** Prefer flags that narrow at the
  source (`--json` with a filter, `--stat`, `--name-only`, `-o`, `-q`) over
  printing everything and picking through it.
- **Make checks self-reporting.** A verification script should print a verdict —
  expected versus actual — not output for me to eyeball.
- **Batch.** Independent commands go in one call, not one round trip each.
- **If it has to hold every time, put it in CI.** A check you would otherwise
  repeat by hand every session belongs in a workflow.

Don't offload when it costs correctness:

- **Judgment doesn't offload.** Reviewing code, weighing an approach, deciding
  whether wording is right — a command can find candidates, it can't decide.
  Read the code you are reasoning about.
- **Don't write a fragile parser to avoid a short read.** If getting the script
  right is harder than reading the thing, read the thing.
- **Don't trust output you can't sanity-check.** A clever one-liner whose result
  you have no way to verify is worse than the slow, obvious path.
- **Keep the evidence that matters.** When something fails I want the actual
  failure output, not a summarized verdict.
- **Never quietly sample.** If you filtered, truncated, or checked only part of
  something, say so. A partial check reported as a complete one is worse than
  no check at all.

# Feature development workflow

**For anything bigger than an obvious fix, put something concrete in front of me
and wait for a yes before implementing.**

When I ask for a new feature or a significant change (as opposed to a bug fix,
small tweak, or something I've already specified in detail):

- Do **not** jump straight into implementation.
- First give me something concrete to react to. Pick whichever fits the task:
  - **Mockup** — an ASCII sketch, quick HTML page, or description of the UI/UX
  - **Demo / spike** — a minimal throwaway version that shows the core idea working
  - **Options** — 2–3 approaches with trade-offs and a recommendation
  - **Direction** — a short proposal: approach, affected files, data model, risks
- Wait for my confirmation or feedback before writing production code.

Skip this ceremony when:

- The change is small and unambiguous (rename, typo, obvious bug fix)
- I've explicitly said to just build it
- I've already approved a direction and this is a follow-up within it

# Git

**Nothing is committed or pushed unless I ask; finished work goes to a pull
request that merges only on green.**

- Never commit or push unless I ask (or I've clearly set up a workflow where
  it's expected). This governs *whether* to commit; the rest of this section
  governs *how* the work is carved up once I've asked.
- Commit in atomic units: one logical change each — one feature, one fix, one
  refactor, one documentation update — so every commit is independently
  revertable and describable in a single line. Don't bundle unrelated changes,
  and don't dump a whole session into one commit called "updates".
- Write the message as a conventional prefix plus an imperative summary, with
  the reasoning in the body when it isn't obvious from the diff. Prefixes:
  `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `style:`, `perf:`, `chore:`.
- Don't commit code that doesn't build, tests that fail (unless a failing test
  is deliberately the point), leftover debugging, or unrelated changes mixed
  together.
- Reshaping history on a feature branch is fine and needs no confirmation,
  before or after pushing it: squash the fixups, reorder, reword, split a "wip"
  into the commits it should have been, and force-push the result. Until it
  merges, the branch is yours. `git log origin/main..HEAD` shows what's in
  scope.
- **`main` is the line.** Never rewrite history there — no force-push, no
  rebase, no amending a merged commit — without explicit confirmation. The same
  restraint applies to any branch someone else has started work from, which is
  the reason the rule exists.
- Once work on a branch is complete and pushed, go ahead and open a pull
  request by default — no need to ask first.
- After opening a pull request, keep watching it if the tooling allows:
  respond to review comments and fix CI failures until it's merged or closed.
- Merge pull requests by default once automated checks pass and any required
  reviews are approved — no need to ask first. Don't merge over failing
  checks, missing required approvals, or unresolved discussions.
- Squash-merging a pull request is fine even though it collapses the branch:
  `main` is meant to carry one commit per change, which is the unit `revert`
  and `bisect` work on, and the commit-by-commit story stays readable in the
  pull request. That is a reason to keep the branch's story clean, not a
  reason to stop telling one — reviewers read it commit by commit.
- Never commit secrets, `.env` files, or credentials — flag it if you see
  them staged.

## Using GitHub tooling efficiently

- Ask for the smallest useful response: set `minimal_output` where the tool
  supports it, page in small batches, and use server-side filters instead
  of fetching everything and filtering after.
- Don't pull a large payload to read one field. When polling something like
  a workflow or check status, request only that status; if a response comes
  back huge anyway, save it and query the field out of the file rather than
  re-fetching.
- Prefer a scheduled re-check over tight polling loops when waiting on CI
  or a deployment.

# Project website

**Most projects get a static site — what it is, why it exists, how to use it —
with demos simulated and labeled when real ones aren't practical.**

- Most projects should have a static website (GitHub Pages or similar)
  covering: what the project is, why it exists, and how to use it.
- Show the project in action. Where real screenshots or live demos aren't
  practical, simulate them — rendered terminal sessions, mocked UI states,
  example output — and label simulated content as such.
- Include a before/after demo showing what the project actually changes:
  the same scenario with and without it, side by side.
- Give install steps for every environment where they differ (local CLI,
  cloud/web, IDE, settings-UI-only tools), not just the common case —
  and say *why* a variant differs, so the reader can generalize.
- Keep the site in the repo (e.g. a `docs/` folder) so it versions with
  the code, and update it alongside user-facing changes.
- Publish via the GitHub Actions Pages path by default: Pages source set
  to "GitHub Actions", with a workflow using `actions/configure-pages`,
  `actions/upload-pages-artifact`, and `actions/deploy-pages` — not the
  legacy deploy-from-branch mode.
- Plain static HTML/CSS is fine; don't introduce a site generator or
  framework unless the project already has one or genuinely needs it.
- Skip the site for internal scratch work, private utilities, or projects
  too small for it to add anything — and ask before publishing anything
  publicly for the first time.

# Repo configuration as code

**Repository settings live in the repo as code and are applied automatically,
never clicked through the web UI.**

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

# Secrets and sensitive data

**Secrets are stopped by three independent layers, and a failing check is never
quietly disabled.**

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

# Specification

**For anything beyond a small change, keep a written specification in the repo,
in a standard format, and keep it true.**

The current format is
[Spec Kit](https://github.com/github/spec-kit).

- **Where it lives:** one directory per feature under `specs/`, holding
  `spec.md` (the intended behavior) and, where the tooling is in use,
  `plan.md` (technical approach) and `tasks.md` (work breakdown).
  Project-wide principles go in `.specify/memory/constitution.md`.
- **The spec is the contract.** It states what the software should do and why
  — behavior, constraints, acceptance criteria — not how the code achieves it.
  Implementation detail belongs in `plan.md`.
- **Keep it current.** When intended behavior changes, revise `spec.md` in the
  same change as the code; never leave it describing behavior that no longer
  exists. Then bring `plan.md` and `tasks.md` back in line with it. Same rule
  as `ARCHITECTURE.md`.
- **Never let them disagree silently.** If you find code that contradicts the
  spec, say so and ask which one is wrong. Don't quietly rewrite the spec to
  match whatever the code happens to do.
- **It pairs with the feature workflow.** For a significant feature the spec,
  or a draft of it, is usually the concrete thing to react to: write it, show
  me, wait for a yes before implementing. Don't chain the generation commands
  straight through to implementation unattended.
- **Tooling:** when a project already has `.specify/`, use its commands —
  `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`,
  `/speckit.analyze`, `/speckit.implement`, `/speckit.converge`. When it
  doesn't, ask before adding the toolchain: `specify init` reshapes the repo,
  so it isn't a unilateral call, and a hand-written `spec.md` in the same
  shape is fine on its own.

Skip all of this for small, unambiguous changes, one-off scripts, and
throwaway spikes — the same threshold as the feature workflow.

# Testing

**Start from a failing test that captures the expected behavior, then write the
code that makes it pass — and show me both runs.**

- Write tests **before** implementation by default: start from a failing test
  that captures the expected behavior, then write the code to make it pass.
- Show me the failing test run before the fix and the passing run after —
  that's the evidence the test actually exercises the change.
- When fixing a bug, first add a test that reproduces it.
- Test behavior, not implementation details; don't write tests that just
  mirror the code's internals or mock everything into meaninglessness.
- Use the project's existing test framework and conventions. If the project
  has no test setup at all, propose one before introducing it.

Skip test-first when:

- It's a throwaway spike, mockup, or exploration (per the feature workflow)
- The change isn't meaningfully testable (docs, comments, formatting, config)
- I've explicitly said to skip tests

# Tool fallbacks

**When an interactive tool looks stuck, switch to plain text rather than retrying
the thing that just broke.**

- If an interactive tool looks stuck — the same prompt keeps reappearing, a
  response never arrives, or I say I answered something you never received —
  stop using that tool and continue in plain text. Say that you're switching
  and why.
- A rejection is not always a refusal. If a tool reports that I declined but I
  say I answered, treat it as lost input rather than a decision, and re-ask in
  plain text.
- Never re-ask through a mechanism that just failed. Two failures of the same
  kind mean change approach, not retry — retrying is what turns one lost
  answer into a loop.
- Known issue behind this rule: dismissing an `AskUserQuestion` card silently
  discards typed free text, and a resolved card can keep re-rendering on
  mobile until the app restarts —
  <https://github.com/anthropics/claude-code/issues/81223>. If either happens,
  fall back to plain text and suggest restarting the app.
- This applies to any tool, not just question prompts: when something fails
  repeatedly, use the simplest thing that works — plain text, a file, a shell
  command — and tell me what you fell back to.
- When a tool failure may have destroyed something I typed, say so explicitly
  instead of quietly proceeding on a guess.

<!-- END dotfiles-ai -->
