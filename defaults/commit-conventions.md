# Commit and branch conventions

**Nothing is committed or pushed unless I ask; each commit is one logical
change, conventionally named.**

- Never commit or push unless I ask (or I've clearly set up a workflow where
  it's expected). This governs *whether* to commit; the rest of this module
  governs *how* the work is carved up once I've asked.
- Commit in atomic units: one logical change each — one feature, one fix, one
  refactor, one documentation update — so every commit is independently
  revertable and describable in a single line. Don't bundle unrelated changes,
  and don't dump a whole session into one commit called "updates".
- Write the message as a conventional prefix plus an imperative summary, with
  the reasoning in the body when it isn't obvious from the diff. Prefixes:
  `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `style:`, `perf:`, `chore:`.
- Name branches the same way: a type prefix, then a short hyphenated
  description — `fix/marker-trailing-space`, `docs/install-guide`. It should
  still say what it is a month later, read in a list of twenty. If the repo
  already has a convention, follow that one instead of introducing a second.
- Don't commit code that doesn't build, tests that fail (unless a failing test
  is deliberately the point), leftover debugging, or unrelated changes mixed
  together.
- Never commit secrets, `.env` files, or credentials — flag it if you see them
  staged. The scanning layers that back this up are in the secrets module.

## Rewriting history

- Reshaping history on a feature branch is fine and needs no confirmation,
  before or after pushing it: squash the fixups, reorder, reword, split a "wip"
  into the commits it should have been, and force-push the result. Until it
  merges, the branch is yours. `git log origin/main..HEAD` shows what's in
  scope.
- **`main` is the line.** Never rewrite history there — no force-push, no
  rebase, no amending a merged commit — without explicit confirmation. The same
  restraint applies to any branch someone else has started work from, which is
  the reason the rule exists.
