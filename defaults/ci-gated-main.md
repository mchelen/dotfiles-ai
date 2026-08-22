# CI-gated main

**`main` is protected, and merges only through a green CI check.**

*GitHub-specific in mechanism; the rule — no unreviewed, untested code on the
default branch — carries to any forge.*

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
