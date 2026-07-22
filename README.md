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
| [`testing.md`](defaults/testing.md) | Tests come **before** implementation; bug fixes start from a reproducing test |
| [`architecture.md`](defaults/architecture.md) | Every project keeps an up-to-date `ARCHITECTURE.md` with Mermaid diagrams |
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

## Usage by tool

There are three delivery mechanisms, depending on what a given tool reads:

1. **User-level file** — `install.sh` writes it for you; applies to every
   project on the machine.
2. **Settings UI** — paste the output of `./install.sh --print` into the
   tool's rules/instructions setting.
3. **Repo file** — commit the block (or a subset of modules) into a file in
   the project itself; needed for cloud/web agents that only see the repo.

| Tool | Surface | Where the defaults go | Mechanism |
|---|---|---|---|
| **Claude Code** | CLI, desktop app, IDE extensions | `~/.claude/CLAUDE.md` (user memory) | `install.sh` ✅ |
| **Claude Code** | Web (claude.ai/code) | The repo's own `CLAUDE.md` | repo file |
| **Codex** | CLI | `~/.codex/AGENTS.md` | `install.sh` ✅ |
| **Codex** | Web/cloud, IDE extension | The repo's `AGENTS.md` | repo file |
| **GitHub Copilot** | VS Code / JetBrains chat | Repo's `.github/copilot-instructions.md`; VS Code also supports user-scoped `*.instructions.md` files | repo file / settings UI |
| **GitHub Copilot** | Web (github.com chat) | Personal custom instructions in Copilot settings | settings UI |
| **GitHub Copilot** | Coding agent | Repo's `AGENTS.md` or `.github/copilot-instructions.md` | repo file |
| **Cursor** | IDE | User Rules (Cursor Settings → Rules) | settings UI |
| **Gemini CLI** | CLI | `~/.gemini/GEMINI.md` | add to `TARGETS` |
| **Windsurf** | IDE | Global rules (settings) | settings UI |

Notes:

- **Adding a file-based tool**: append its path to the `TARGETS` array in
  `install.sh` and re-run — anything that reads a user-level markdown file
  works the same way (e.g. Gemini CLI above).
- **Repo files**: for cloud agents, either paste the `--print` output into the
  project's `CLAUDE.md`/`AGENTS.md`, or copy just the modules that matter for
  that project. Keep in mind those files are shared with collaborators —
  personal preferences you don't want to impose on others belong at the user
  level.
- Tool locations change; if a tool ignores its file, check that tool's
  current docs for where user instructions live.

## Adding your own defaults

1. Drop a new `.md` file in `defaults/` — one topic per file, phrased as
   direct instructions to the assistant.
2. Re-run `./install.sh`.

Keep modules short and unconditional enough to apply everywhere; anything
that only applies to one project belongs in that project instead.
