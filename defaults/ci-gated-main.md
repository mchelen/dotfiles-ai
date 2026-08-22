# Pull requests and a CI-gated `main`

**Changes reach `main` only through a pull request with a green check.**

*The working half is tool-agnostic. The protection half is GitHub-specific in
mechanism — the rule, no unreviewed or untested code on the default branch,
carries to any forge — and needs admin rights, so it's a one-time human step.*

## Working this way

- Once work on a branch is complete and pushed, open a pull request by
  default — no need to ask first.
- After opening it, keep watching it if the tooling allows: respond to review
  comments and fix CI failures until it's merged or closed. A pull request you
  opened and stopped watching is unfinished work, not delivered work.
- Merge by default once automated checks pass and any required reviews are
  approved — no need to ask first.
- Don't merge over failing checks, missing required approvals, or unresolved
  discussions. A red check is an answer, not an obstacle.
- When a check is red for a reason the change didn't cause — a flaky test, a
  failure that reproduces on the base branch — say that in the pull request
  and merge once it recovers, rather than quietly merging past it.
- Squash-merging is fine even though it collapses the branch: `main` is meant
  to carry one commit per change, which is the unit `revert` and `bisect` work
  on, and the commit-by-commit story stays readable in the pull request. That
  is a reason to keep the branch's story clean, not a reason to stop telling
  one — reviewers read it commit by commit.

## Protecting the branch

The rules above are what I want you to do. Branch protection is what the
repository does when nobody is doing it — including when the actor is a script.

- **Protect the default branch.** No direct pushes, no force-pushes, no
  deletion. Changes reach `main` through a pull request.
- **Require at least one status check**, and require it to *pass* — a check
  that runs but isn't required is a suggestion. Include administrators in the
  rule: a gate you can walk around is a gate for other people.
- **The check does real work, honestly.** Install dependencies, build the
  project if it has a build, run the tests if it has tests. Where there is
  neither, the check should say so in its output and pass — not print a green
  tick that means nothing. A check that always passes is worse than no check,
  because it looks like coverage.
- Keep it fast enough that nobody wants to bypass it. If the full suite is
  slow, gate on the fast subset and run the rest after merge.
- **Configure it as code**, through whatever mechanism the repo already uses
  for settings (see the repo-config module) — not by clicking through branch
  protection screens.

## Automation that pushes to `main`

Branch protection blocks bots too. Before enabling it, look for workflows that
commit or push to the default branch — a docs generator, a formatter, a
version bumper — because they will start failing.

Resolve it deliberately, and say which you chose:

- Give that one workflow a documented bypass, narrowest possible; or
- Convert it to open a pull request instead of pushing.

Preferring the second is usually right: it keeps the gate absolute, and the
bot's output gets the same review as anyone else's.

## Setting it up for the first time

Branch protection needs admin rights, so it is a one-time human step. Write out
what to do rather than stalling or assuming, in the same shape the repo-config
module describes: which rule to add, which check to mark required, whether
administrators are included, and what happens to any existing bot pushes.

Then confirm it took effect — read the protection back, or open a throwaway
pull request and check that merge is blocked until the check reports. An
unenforced rule and an enforced one look identical from the settings page.
