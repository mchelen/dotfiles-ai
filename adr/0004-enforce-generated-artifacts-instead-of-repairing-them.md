# 4. Enforce generated artifacts in CI instead of repairing them with a bot

- **Status:** Proposed — this record exists to support one decision, stated
  under [Decision](#decision). Branch protection is not yet enabled.
- **Date:** 2026-08-23

## Context

This repo does not follow its own `ci-gated-main` module. `main` is
unprotected, and one workflow is the reason: `generate-instructions`
regenerated `INSTRUCTIONS.md`, `INSTRUCTIONS-brief.md`, and the module text in
`docs/index.html` after a module changed, and pushed the result straight to
`main`. Protect the branch and that push starts failing.

The module recommends converting such a workflow to open a pull request
instead. Attempting that ran into a constraint. Events raised by the built-in
`GITHUB_TOKEN` do not start workflow runs — from
`peter-evans/create-pull-request`'s documentation:

> When you use the repository's `GITHUB_TOKEN` to perform tasks, events
> triggered by the `GITHUB_TOKEN` will not create a new workflow run.

So a pull request the workflow opened would carry no checks, and under a
required-check rule could never merge. Getting out of that needs a
fine-grained PAT or a GitHub App token purely so the checks fire, plus
auto-merge so the browser-editing path stays one step.

That was the shape of the first proposal. It works, and it is more machinery
than the problem deserves.

### The reframing

The restriction is on **workflows acting as themselves**. It has nothing to do
with a pull request opened by a person, or by an agent working through the
GitHub API with a normal identity — those trigger checks like any other. Every
pull request in this repo's recent history was opened that way and ran its
full suite.

Which invites the question the first proposal skipped: *who is regenerating
these files, and why is it a bot?* In practice a module is changed by someone
with a working copy — a person or a coding agent — and that same actor can run
`install.sh --print` in the same change. The bot existed to repair a mistake
nobody had to make.

Repairing it after the fact is also strictly worse than preventing it. A
repair bot needs write access to the default branch, an identity able to hold
it, and a bypass or a token; a check needs none of those and works in a fork
from the moment it is created.

### The gap this exposed

`test.sh` already verified `docs/index.html` against `defaults/` — but not the
other two artifacts. A change that ran `build-site.sh` and forgot
`install.sh --print` passed. Confirmed by doing it: the suite went green with
a stale `INSTRUCTIONS.md`, which is the file the no-terminal install path
serves to anyone who copies it.

## Decision

**Delete the regeneration workflow. Make `test.sh` fail when any generated
artifact differs from what the tools produce, and regenerate in the same
change as the module edit.**

- Two checks added, mirroring the existing `build-site.sh --check`: committed
  `INSTRUCTIONS.md` and `INSTRUCTIONS-brief.md` must equal `install.sh --print`
  and `install.sh --brief`.
- `.github/workflows/generate-instructions.yml` is removed, and with it the
  `workflow_run` trigger on `deploy-pages` that existed only because the bot's
  `GITHUB_TOKEN` pushes could not trigger it.
- No token, no bypass, nothing to rotate. `main` can be protected with
  administrators included and an empty bypass list.

## Considered options

**A. Enforce in CI, regenerate in the change** *(this decision)*. No
credential, no new identity, works in any fork immediately. The gate can be
absolute. Costs: whoever edits a module must run a command, and someone
editing only in a browser cannot finish the change alone.

**B. Bot opens a pull request, PAT-backed, auto-merging on green**. Keeps
browser-only editing whole. Costs a fine-grained PAT to mint and rotate, a
repo setting (`allow_auto_merge`), two code paths in the workflow, and a
generated pull request merging itself unreviewed. This was the first proposal;
it is a lot of moving parts to preserve one path.

**C. Ruleset bypass for `github-actions[bot]`**. Cheapest to build, keeps the
bot as-is. But the gate stops being absolute, and the exception is granted to
an actor rather than to a workflow, so every future workflow inherits it
without anyone re-deciding.

**D. Regenerate at read time instead of committing**. Removes the artifact
and the problem. Rejected: the whole point of `INSTRUCTIONS.md` is that a
browser user can open one file in a fork and copy it.

## Consequences

- Branch protection becomes possible with no exceptions, which is what
  `ci-gated-main` asks for and this repo has never satisfied.
- The staleness gap is closed, and the check that closes it is the same shape
  as the one already trusted for the site.
- **A module edited entirely in the browser can no longer be completed
  alone.** The change will fail its check until someone with a shell or an
  agent regenerates. The install guide now says this plainly instead of
  implying the browser suffices for editing. Every *read* path — which is what
  the no-terminal promise actually covers — is untouched.
- Two module changes in flight will conflict on the artifacts, and the second
  needs a rebase and a re-run. Previously the bot papered over that after the
  fact, sometimes with a stale result.

## What I am unsure about

- **Whether browser-only editing mattered.** It is a real capability being
  given up, and I do not know if anyone used it. It was cheap when the bot
  pushed directly; under branch protection it costs a PAT, and that changed
  the arithmetic rather than the value.
- **Conflict friction.** With one maintainer this is rare. With several, every
  concurrent module change collides on three generated files, and a
  regenerate-on-merge bot starts looking reasonable again — which is what
  option B or C would be for.

## Revisit when

- More than one person is regularly editing modules and artifact conflicts
  become routine. That is the signal that generation belongs after the merge
  rather than inside the change.
- A GitHub App is installed here for another reason. Its token triggers
  workflows, so option B loses its main cost and browser-only editing could be
  restored without a PAT to rotate.
- GitHub lets `GITHUB_TOKEN`-raised events start workflow runs, or ships a
  bypass scoped to a workflow rather than an actor.
