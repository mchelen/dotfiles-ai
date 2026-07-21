# dotfiles-ai

Dotfiles, but for AI coding assistants: a set of reusable, personal defaults
for how an AI assistant should work with you — carried across projects and
tools instead of re-explained in every session.

Like classic dotfiles, these encode *individual* preferences (workflow,
communication style, guardrails), not project conventions. Project-specific
instructions still belong in each repo's own `CLAUDE.md` / `AGENTS.md`.

## What's here

Each file in [`defaults/`](defaults/) is one self-contained preference module,
written as plain tool-agnostic markdown:

| Module | Preference |
|---|---|
| [`feature-workflow.md`](defaults/feature-workflow.md) | New features get a mockup, demo, options, or direction proposal **before** implementation starts |
| [`communication.md`](defaults/communication.md) | Answer-first replies, push back on bad ideas, disclose gaps |
| [`code-style.md`](defaults/code-style.md) | Match the codebase, minimal diffs, no drive-by refactors or dependencies |
| [`git.md`](defaults/git.md) | No commits/pushes unless asked, no history rewrites, no secrets |

## Install

```sh
./install.sh
```

This concatenates the modules and inserts them as a clearly-marked managed
block in each tool's user-level instruction file:

- `~/.claude/CLAUDE.md` — Claude Code (user memory)
- `~/.codex/AGENTS.md` — OpenAI Codex CLI

Re-running the script replaces the managed block in place (a `.bak` backup is
saved), so anything you keep in those files outside the block is untouched.
For tools that only accept rules through a settings UI (e.g. Cursor's User
Rules), paste the output of `./install.sh --print`.

## Adding your own defaults

1. Drop a new `.md` file in `defaults/` — one topic per file, phrased as
   direct instructions to the assistant.
2. Re-run `./install.sh`.

Keep modules short and unconditional enough to apply everywhere; anything
that only applies to one project belongs in that project instead.
