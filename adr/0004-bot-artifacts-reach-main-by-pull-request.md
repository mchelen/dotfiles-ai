# 4. Generated artifacts reach `main` by pull request, not by bypass

- **Status:** Proposed — this record exists to support one decision, stated
  under [Decision](#decision). Nothing has been enabled.
- **Date:** 2026-08-23

## Context

This repo does not follow its own `ci-gated-main` module. `main` is not
protected, and the reason is one workflow: `generate-instructions` regenerates
`INSTRUCTIONS.md`, `INSTRUCTIONS-brief.md`, and the module text in
`docs/index.html` whenever `defaults/` changes, and pushes the result straight
to `main`. Turn on branch protection and that push starts failing.

The module names both ways out, and prefers one:

> Give that one workflow a documented bypass, narrowest possible; or convert
> it to open a pull request instead of pushing. Preferring the second is
> usually right: it keeps the gate absolute, and the bot's output gets the
> same review as anyone else's.

Converting to a pull request turned out to have a constraint that was not
obvious when that sentence was written.

### The constraint

Events raised by the built-in `GITHUB_TOKEN` do not start workflow runs.
From `peter-evans/create-pull-request`'s own documentation:

> When you use the repository's `GITHUB_TOKEN` to perform tasks, events
> triggered by the `GITHUB_TOKEN` will not create a new workflow run.

So a pull request opened by the workflow with the default token has **no
checks at all**. Under a rule that requires a status check to pass, it can
never merge — the conversion produces a pull request that is stuck by
construction. This is the same behaviour that made `deploy-pages` need a
`workflow_run` trigger a few changes ago; it bites harder here.

The documented workarounds are a fine-grained PAT, a GitHub App token, a
machine account pushing from a fork, or manual close-and-reopen. All but the
last need a credential that does not exist yet, and creating one is a step an
assistant cannot do.

### The second cost, and what removes it

A bot pull request also threatens the property that makes the no-terminal
install path work: someone edits a module in the GitHub web editor, and
`INSTRUCTIONS.md` is current straight afterwards. If the regeneration lands in
a pull request a human must merge, that path becomes two steps, and the second
one is easy to forget — leaving the artifact stale, which is the exact failure
the workflow exists to prevent.

Auto-merge removes it. The pull request merges itself when its checks are
green, so the web-editor path stays one step. What the gate buys is not human
review of a generated diff — nobody reads those — it is that the generated
files pass through the same checks as everything else. Auto-merge keeps that
and drops the friction.

## Decision

**Convert `generate-instructions` to open a pull request that auto-merges on
green, and require a fine-grained PAT so the checks actually run.**

Not yet enabled, because it needs a one-time human step and a choice about
whether the cost is worth it. What is built, on
`claude/bot-prs-for-generated-artifacts`:

- The workflow commits regenerated artifacts to `bot/regenerate-artifacts`,
  force-pushing so there is one open pull request rather than an accumulating
  pile, opens it with `gh`, and calls `gh pr merge --auto --squash`.
- The push uses `ARTIFACT_BOT_TOKEN` (Contents: write, Pull requests: write).
  This is what makes the checks run. It is deliberately not `REPO_ADMIN_TOKEN`
  — that one administers settings, and routine commits should not carry
  administrative scope.
- `infra/main.tf` sets `allow_auto_merge = true`, without which
  `gh pr merge --auto` fails.
- Until the secret exists the job falls back to pushing directly — today's
  behaviour. That fallback stops working the moment branch protection is
  enabled, and it fails loudly rather than skipping quietly.

No new action dependency: `gh` is pre-installed on GitHub-hosted runners, so
this is the CLI rather than a third-party action.

## Considered options

**A. Pull request with auto-merge, PAT-backed** *(this decision)*. The gate is
absolute — no actor bypasses it, bot or human — and the generated files are
checked like everything else. Costs a fine-grained PAT to mint and rotate, and
one more moving part in a workflow.

**B. Ruleset bypass for `github-actions[bot]`**. No credential, no new
machinery, no rotation. But the gate stops being absolute: anything running as
that actor can write to `main`, and the set of things running as that actor
grows over time without anyone re-deciding this. It also leaves the generated
artifacts as the one kind of change that reaches `main` unchecked, which is
awkward for a repo whose own module says a gate you can walk around is a gate
for other people.

**C. Move regeneration to a local pre-commit hook**. No bot, no token, no
bypass. Rejected already and still rejected: modules edited through the GitHub
web editor have no local hook to run, and that path is the whole point of
`INSTRUCTIONS.md` existing.

**D. Stop generating and commit artifacts by hand**. Removes the problem by
removing the feature. The artifacts would be stale most of the time.

## Consequences

- Branch protection can be enabled with administrators included and no bypass
  list, which is what `ci-gated-main` asks for and this repo has not been able
  to do.
- One more secret to hold and eventually rotate. Its scope is narrow enough
  that leaking it costs commits and pull requests on one repo, not settings.
- The regeneration path gains a failure mode it did not have: if checks are
  red, the artifact pull request sits open instead of merging. That is
  correct — stale artifacts are better than artifacts that skipped the
  checks — but it is a state someone has to notice.
- `allow_auto_merge` becomes part of the declared settings, so the weekly
  drift check covers it.

## What I am unsure about

- **Whether auto-merge is a dodge.** It keeps the gate honest in the sense
  that matters here — the checks run — but it does mean nothing is ever
  reviewed. That is fine for generated files and would not be fine for
  anything else, so the risk is the pattern spreading by example.
- **The fallback path.** Keeping direct-push-when-no-token means two code
  paths in one workflow, and the untested one is the one that runs today.
  Deleting it would be cleaner and would break artifact regeneration until
  the secret exists.
- **Untested end to end.** No token exists, so the pull-request branch of this
  workflow has never run. The YAML parses and the shape follows
  `repo-settings.yml`, which does work, but the first real run is the first
  real test.

## Revisit when

- GitHub makes `GITHUB_TOKEN`-raised events start workflow runs, or ships a
  first-class "let this workflow bypass protection" primitive that is scoped
  to a workflow rather than an actor. Either removes the reason for the PAT.
- A GitHub App is installed on this repo for another reason — the Settings
  app, say. Its token triggers workflows too, and would replace the PAT
  without a second credential to rotate.
- The artifact pull request starts needing human attention regularly. That
  would mean the checks are catching real problems in generated output, and
  the generation is what should be fixed.
