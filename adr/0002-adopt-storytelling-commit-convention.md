# 2. Adopt the storytelling commit convention, scoped to two existing rules

- **Status:** Accepted
- **Superseded in part by** [ADR-0003](0003-curate-skills-on-the-agent-skills-standard.md):
  the "Not adopted: the packaging" reasoning was wrong. The convention's
  adoption and both tension resolutions stand.
- **Date:** 2026-07-26
- **File moved, 2026-08-22:** `defaults/git.md` was later split three ways —
  message and branch conventions to `commit-conventions.md`, pull requests and
  merging folded into `ci-gated-main.md`, forge-query efficiency to
  `cheap-git-queries.md`. Every rule this record names still exists; the
  paths below are where they lived when it was written. Nothing about the
  decision changed, so this is a pointer, not an amendment.

## Context

An external convention — packaged elsewhere as a "git storytelling commit
strategy" skill — was proposed for adoption. Its substance: commit in atomic
units, use conventional message prefixes, and clean up local commits with an
interactive rebase before pushing so a branch reads as a deliberate sequence
rather than a pile of "wip".

Most of it is compatible with `defaults/git.md` as written, and one part that
looked like a conflict isn't. The convention's rule is that rebasing is safe
for unpushed commits and dangerous for pushed ones — with an explicit exception
for "personal feature branches where you're the only contributor". Asked where
the line should sit, the repository owner placed it there too: tidying before
pushing or rewriting a branch before it merges are both fine, and the thing
that must not be rewritten is `main`. But two genuine tensions remain, and both
are with rules this project actively holds.

## Decision

Adopt the convention, with both tensions resolved in the module text rather
than left to collide.

### Tension 1 — "commit early and often" vs. "never commit unless I ask"

The convention's headline practice is frequent committing, including before
context switches. `git.md` says nothing is committed unless asked, which is a
deliberate guardrail against an assistant committing on its own initiative.

**Resolved by separating authorization from granularity.** Whether to commit
stays with the person: unchanged. How the work is carved up once a commit has
been asked for is where the convention applies — atomic units rather than one
dump. The module now says this explicitly, because the two rules read as
contradictory otherwise.

### Tension 2 — the "Time Machine" anti-pattern vs. squash-merge

The convention names squashing a branch's commits into one as an anti-pattern
that "destroys the development story entirely". This repository squash-merges
every pull request, and merge commits and rebase-merging are disabled in
`infra/main.tf` — so on paper it commits the anti-pattern every time.

**Resolved by naming the trade rather than pretending it away.** `main` is
meant to carry one commit per change, because that is the unit `git revert` and
`git bisect` operate on and the unit a reader scanning history wants. The
commit-by-commit story is preserved in the pull request, which is where it is
actually read. This makes clean branch history *more* valuable, not less —
reviewers read it commit by commit — so the convention still applies in full up
to the merge button.

## Not adopted

- **The attribution trailer block** in the convention's example messages. Trailer
  policy is already handled by the environment, and a second source of it would
  produce duplicates.
- **The commit-reminder hook** the convention references. It only makes sense
  paired with "commit early and often" as an unprompted practice, which
  Tension 1 resolves the other way.
- **The packaging.** It was offered as a Claude skill. Skills live in
  `~/.claude/skills/`, which is Claude-only and machine-local — it fails the
  cross-provider requirement in [ADR-0001](0001-forkable-repo-for-personal-ai-preferences.md).
  A commit convention is an always-relevant behavioral rule, so it belongs in
  the resident block, as a module. The content was adopted; the container was
  not.

## Consequences

- `defaults/git.md` grows by roughly a third: message format, what not to
  commit, and the pre-push cleanup rule are all new.
- The prohibition on rewriting history is **narrowed**, deliberately, on the
  owner's instruction: it now attaches to `main` — and to any branch someone
  else has built on — rather than to the act of pushing. Rewriting an
  unmerged feature branch, force-push included, no longer needs confirmation.
  This matches both the convention's stated exception and how this repository
  is actually worked, where the feature branch was reset and force-pushed
  repeatedly while `main` was never touched.
- Anyone reading `git.md` alongside `infra/main.tf` will see squash-merge
  addressed rather than have to wonder whether it was noticed.

## Revisit when

- The repository stops squash-merging, which removes Tension 2 entirely.
- Conventional-commit prefixes start driving automation here — changelog
  generation or release tagging — at which point the prefix list stops being a
  style preference and becomes an interface, and needs its own record.
