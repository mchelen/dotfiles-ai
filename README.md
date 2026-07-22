# dotfiles-ai

Dotfiles, but for AI coding assistants: a set of reusable, personal defaults
for how an AI assistant should work with you — carried across projects and
tools instead of re-explained in every session.

**Website:** <https://mchelen.github.io/dotfiles-ai/> (serve `docs/` with
GitHub Pages: Settings → Pages → deploy from branch `main`, folder `/docs`)

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
| [`project-website.md`](defaults/project-website.md) | Most projects get a static site (GitHub Pages) with usage docs and (simulated) screenshots/demos |
| [`git.md`](defaults/git.md) | No commits/pushes unless asked, no history rewrites, no secrets |

## Install

```sh
./install.sh
```

This concatenates the modules and inserts them as a clearly-marked managed
block in the user-level instruction file of each AI CLI it detects on your
machine (detection = the tool's config directory exists). Use
`./install.sh --all` to write every target regardless.

Re-running the script replaces the managed block in place (a `.bak` backup is
saved), so anything you keep in those files outside the block is untouched.

## Keeping machines in sync

Installed blocks are copies — they only change when `install.sh` runs. Two
pieces of automation keep them current, so the flow is: edit `defaults/` on
any machine → merge to `main` → every other machine picks it up on its next
shell start (or next `git pull`).

**1. Shell startup** — add to `~/.zshrc` / `~/.bashrc`:

```sh
[ -x "$HOME/dotfiles-ai/sync.sh" ] && "$HOME/dotfiles-ai/sync.sh" --auto
```

`sync.sh --auto` pulls the latest `main` and re-runs the installer, at most
once per day (override with `DOTFILES_AI_SYNC_INTERVAL`, in seconds). It's
completely silent when there's nothing new, when offline, or when throttled,
so it doesn't clutter shell startup; it prints only when defaults actually
changed.

**2. Manual pulls** — `sync.sh` configures `core.hooksPath` so the
versioned [`hooks/post-merge`](hooks/post-merge) hook re-runs `install.sh`
after any `git pull` in this repo. Installed files never lag the checkout.

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
| **GitHub Copilot** | CLI | `~/.copilot/copilot-instructions.md` | `install.sh` ✅ |
| **GitHub Copilot** | VS Code / JetBrains chat | Repo's `.github/copilot-instructions.md`; VS Code also supports user-scoped `*.instructions.md` files | repo file / settings UI |
| **GitHub Copilot** | Web (github.com chat) | Personal custom instructions in Copilot settings | settings UI |
| **GitHub Copilot** | Coding agent | Repo's `AGENTS.md` or `.github/copilot-instructions.md` | repo file |
| **Gemini CLI** | CLI | `~/.gemini/GEMINI.md` | `install.sh` ✅ |
| **Qwen Code** | CLI | `~/.qwen/QWEN.md` | `install.sh` ✅ |
| **OpenCode** | CLI/TUI | `~/.config/opencode/AGENTS.md` | `install.sh` ✅ |
| **Goose** | CLI | `~/.config/goose/.goosehints` | `install.sh` ✅ |
| **Aider** | CLI | Any file listed under `read:` in `~/.aider.conf.yml` (e.g. point it at `./install.sh --print > ~/.ai-defaults.md`) | manual |
| **Cursor** | IDE | User Rules (Cursor Settings → Rules) | settings UI |
| **Windsurf** | IDE | Global rules (settings) | settings UI |

Notes:

- **Detection**: `install.sh` only writes a target when the tool's config
  directory already exists, so you don't accumulate instruction files for
  tools you never use. `--all` overrides this.
- **Adding a file-based tool**: append its path to the `TARGETS` array in
  `install.sh` and re-run — anything that reads a user-level markdown file
  works the same way.
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
