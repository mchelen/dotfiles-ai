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
