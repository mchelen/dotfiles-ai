# 1. Distribute personal AI preferences as a forkable dotfiles repo

- **Status:** Accepted, provisional — see [Revisit when](#revisit-when)
- **Date:** 2026-07-26

## Context

The same person works across many projects and many assistants: Claude chat,
Claude Code in the terminal, Claude Code on the web, Gemini, Codex, Cursor —
and across several physical machines. A small set of personal preferences
applies to all of them, for example *"open a pull request, and merge it once
the CI checks pass."*

Today those preferences get restated. Every new session, every new tool, every
new machine. There is no obvious place to put them once.

Two distinct problems hide inside that, and they pull in different directions:

1. **Distribution.** Getting the same preferences into any tool, any project,
   any machine, quickly. The per-tool user-level file — `~/.claude/CLAUDE.md`
   and friends — solves this only for one tool on one machine. It is invisible
   to Claude Code on the web, which runs in a fresh container that only has the
   repository; invisible to Codex, which reads its own file; and invisible to
   the laptop you didn't set up.
2. **Accumulation.** Capturing operating knowledge as it is discovered, and
   keeping it. Some of these lessons are not guessable in advance. Example: the
   GitHub MCP server can return responses large enough that reading one costs a
   meaningful share of the context window — so preferring narrow queries over
   fetch-and-scan is worth stating as a standing preference. That was learned by
   hitting it, and would otherwise be re-learned.

The industry has standardized the *project* layer. `AGENTS.md` is a
community-governed convention stewarded by the Agentic AI Foundation under the
Linux Foundation since December 2025, and is read by roughly fifteen tools. The
*personal* layer is not standardized: each tool keeps its own user-level
location, or offers only a settings text box, and none of them syncs.

## Decision drivers

- Must work where there is no local filesystem to write to (cloud agents).
- Must work where there is no terminal at all (web editors, settings-UI tools).
- Must reach a new machine without a per-machine manual step.
- Must be *edited*, not just consumed — these are opinions, and disagreeing with
  one is the normal case.
- Must carry the reasoning, not only the rule, so the accumulation goal is
  actually served.
- Prefer boring and dependency-free over capable and complex.

## Decision

Keep the preferences as small markdown modules in a public git repository, and
treat that repository the way a Linux user treats a dotfiles repo: **fork it,
edit it, and bootstrap it into each new environment.**

Concretely:

- One module per topic in `defaults/`, written as direct instructions, each
  carrying its rationale.
- The modules are assembled into a single marker-delimited block.
- Three delivery paths, because the environments genuinely differ:
  `install.sh` writes the block into per-tool user-level files on a machine; a
  committed `INSTRUCTIONS.md` serves copy-paste and no-terminal use; an
  environment setup script covers cloud sessions.
- Users fork; `sync.sh` keeps machines current from *their* fork.

The dotfiles pattern was chosen because it is a known-good answer to this exact
problem class — bootstrapping personal preferences into new or different
environments — and because it introduces no concepts a reader has to learn
before they can reason about what will happen.

## Considered options

### Per-tool native config only (the baseline)

Every tool already supports user-level instructions. Write the file once per
tool, by hand.

*Rejected as insufficient, not as wrong.* It does not travel: not to another
machine, not to a cloud session that never sees your home directory, not to the
next tool you try. It is still the mechanism this project writes *into*.

### A generic dotfiles manager (chezmoi, GNU Stow, yadm)

`~/.claude/CLAUDE.md` is a dotfile. These tools already do multi-machine sync,
templating, and secrets, and are more capable than `install.sh` will ever be.

*Rejected as the primary mechanism, on two grounds.* They manage whole files,
whereas the requirement here is to own **part** of a file the user also writes
in by hand — hence the marker block, which re-runs replace in place while
leaving everything around it byte-identical. And they assume a filesystem and a
shell, which is exactly what the cloud and no-terminal paths lack. They remain
complementary: managing the *clone* with chezmoi is perfectly reasonable.

### `rulesync` and similar rule-fan-out tools

[`rulesync`](https://github.com/dyoshikawa/rulesync) generates tool-specific
rule files for 20+ tools from one source, supports importing existing configs,
and covers MCP configuration too. On the pure fan-out mechanic it is more
capable than `install.sh`.

*Deferred rather than rejected.* It solves distribution, which is the half of
the problem that is commodity; it has no opinion about *what* the rules should
say, which is the half this project is actually about. Adopting it would add an
npm dependency and would not address cloud or no-terminal delivery. If delivery
becomes the maintenance burden, delegating to `rulesync` is the expected move,
and this decision should be revisited rather than defended.

### `AGENTS.md` as the single file

The emerging standard, read by roughly fifteen tools.

*Adopted within this approach, not instead of it.* It standardizes the
repository file, not the user-level one, so it does not address the personal
layer at all. Note also that Claude Code reads `CLAUDE.md` and **not**
`AGENTS.md`; the documented way to serve both is an `AGENTS.md` plus a
`CLAUDE.md` that imports it with `@AGENTS.md`. Where this project commits a
block into a project repository, that is the shape to use.

### Claude Code auto memory

Claude Code can accumulate learnings by itself, writing notes to
`~/.claude/projects/<project>/memory/`.

*Complementary, not a substitute.* It serves the accumulation goal within one
repository on one machine — the docs are explicit that auto memory is
machine-local and not shared across machines or cloud environments. It cannot
carry a preference to a different tool, a different machine, or a teammate, and
its contents are chosen by the assistant rather than authored deliberately.

### A Claude plugin, skill, or marketplace entry

Real platform support, installable, versioned.

*Rejected on scope.* Single-vendor by construction, and cross-tool reach is the
entire point. Worth reconsidering for Claude-specific ergonomics layered on top.

### Do nothing — restate preferences per session

*Retained deliberately as a supported path.* The quick-start snippet on the
website is this option, made one paste long. For a one-off session it is the
correct amount of effort, and pretending otherwise would be dishonest.

## Consequences

**Positive**

- Works in all three environment classes: local shell, cloud agent, UI-only.
- Personalization is a fork, which is a mechanism people already understand.
- Knowledge accumulates *with its reasoning attached*, which is what makes a
  preference worth keeping rather than re-deriving.
- No runtime dependencies; bash and git.

**Negative**

- The per-tool fan-out in `install.sh` is bespoke, duplicates what `rulesync`
  does better, and grows with every tool added.
- Blocks committed into project repositories are snapshots. Refreshing them is
  manual and deliberately so, but it is still manual.
- The value depends on the modules being good, which is ongoing editorial work,
  not something the tooling can supply.

**Neutral**

- Module categories are a documentation concept only; the directory stays flat.
- `INSTRUCTIONS.md` is generated in CI, so the no-terminal path stays current
  without a local hook.

## Non-goals

- **Project conventions.** Those belong in each repository's own `AGENTS.md` /
  `CLAUDE.md`. This is the layer underneath.
- **Enforcement.** These are instructions in context, not a policy engine. Where
  something must hold regardless of what an assistant decides, use a hook, a
  CI check, or managed settings.
- **Team or organization policy.** Managed-policy `CLAUDE.md` and server-managed
  settings exist for that and are a better fit.
- **Secret material.** Nothing here is private; the repository is public and the
  delivery paths are token-free by design.

## Revisit when

This decision is provisional. Any of the following should reopen it:

- A cross-tool standard for the **user-level** layer emerges — an `AGENTS.md`
  for personal preferences. Most of this collapses into it, and should.
- Tools converge on one user-level file, making the fan-out dead weight.
- `rulesync` or an equivalent grows cloud and no-terminal delivery, at which
  point maintaining a second implementation is hard to justify.
- Per-tool user-level config gains sync of its own, from any vendor.
- The modules stop changing. If accumulation stalls, only distribution is left,
  and distribution is the part worth buying rather than building.
