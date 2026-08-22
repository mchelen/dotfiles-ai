# dotfiles-ai

Dotfiles, but for AI coding assistants: a set of reusable, personal defaults
for how an AI assistant should work with you — carried across projects and
tools instead of re-explained in every session.

**Website:** <https://mchelen.github.io/dotfiles-ai/> — `docs/` published
by the [`deploy-pages` workflow](.github/workflows/deploy-pages.yml);
Pages itself configured as code in [`infra/`](infra/)

Like classic dotfiles, these encode *individual* preferences (workflow,
communication style, guardrails), not project conventions. Project-specific
instructions still belong in each repo's own `CLAUDE.md` / `AGENTS.md`.

## Status: experimental

This is an experiment, not a product. It exists to work out whether personal
defaults can be set once and follow you everywhere — across Claude Code,
Codex, Gemini, web chat, cloud sessions, and however many machines you use —
and to try implementation options for doing it. Nobody has settled that
question. The *project* layer converged on `AGENTS.md`; the *personal* layer
still has each tool keeping its own user-level file, or offering only a
settings text box, and none of them syncing.

A forkable repo of markdown modules, assembled into a marker-delimited block,
is **one** option. The [decision records](adr/) weigh the others — per-tool
config, a general dotfiles manager like chezmoi, `rulesync`, `AGENTS.md`
itself, a tool's own auto-memory, the Agent Skills standard — and name what
would make this approach obsolete;
[`adr/0001`](adr/0001-forkable-repo-for-personal-ai-preferences.md) is marked
*accepted, provisional* and means it.

Read it for the problem framing and the options; fork it if the modules are
useful to you. Don't build on it expecting it to hold still.

## What's here

Each file in [`defaults/`](defaults/) is one self-contained preference module,
written as plain tool-agnostic markdown. Files are flat in `defaults/`; the
four categories below describe the kind of behavior each module governs. Where a
module only applies to a particular assistant or forge, that's noted in italics.

**Collaboration** — how the assistant works with you

| Module | Preference |
|---|---|
| [`honest-reporting.md`](defaults/honest-reporting.md) | Answer-first replies, push back on bad ideas, disclose what's unfinished or still failing |
| [`propose-before-building.md`](defaults/propose-before-building.md) | New features get a mockup, demo, options, or direction proposal **before** implementation starts |
| [`tool-fallbacks.md`](defaults/tool-fallbacks.md) | When an interactive tool looks stuck, fall back to plain text instead of retrying it *(any assistant with interactive prompts)* |
| [`compute-offload.md`](defaults/compute-offload.md) | Let the shell or CI do mechanical work — query instead of reading — but never where judgment or evidence is what's needed *(MCP examples assume MCP)* |

**Craft** — how code gets written

| Module | Preference |
|---|---|
| [`code-style.md`](defaults/code-style.md) | Match the codebase, minimal diffs, no drive-by refactors or dependencies |
| [`testing.md`](defaults/testing.md) | Tests come **before** implementation; bug fixes start from a reproducing test |

**Delivery** — how work ships

| Module | Preference |
|---|---|
| [`git.md`](defaults/git.md) | No commits/pushes unless asked, PRs opened and merged on green, no history rewrites |
| [`secrets.md`](defaults/secrets.md) | Layered secret/PII protection: pre-commit scan + CI scanner + GitHub secret scanning; leaked = rotate *(push protection is GitHub's)* |
| [`ci-gated-main.md`](defaults/ci-gated-main.md) | `main` is protected and merges only on a green check that builds and tests *(GitHub-specific mechanism)* |
| [`repo-config.md`](defaults/repo-config.md) | Repo settings as code — Terraform, or the Settings app — never clicked through the UI, with the one-time human setup spelled out *(GitHub-specific)* |

**Documentation** — what gets written down

| Module | Preference |
|---|---|
| [`architecture-docs.md`](defaults/architecture-docs.md) | Every project keeps an up-to-date `ARCHITECTURE.md` with Mermaid diagrams |
| [`specification.md`](defaults/specification.md) | Intended behavior lives in a checked-in spec (Spec Kit), revised in the same change as the code |
| [`project-website.md`](defaults/project-website.md) | Most projects get a static site with usage docs and (simulated) screenshots/demos *(any static host; Pages assumed)* |

The site has [a full explanation of every module with before/after
examples](https://mchelen.github.io/dotfiles-ai/#modules).

## Install

**Step 0, for everyone: [fork this repo](https://github.com/mchelen/dotfiles-ai/fork).**
Everything below assumes you work from your own fork, for two reasons:

- These modules are one person's preferences and you're *expected* to edit
  them — delete what you disagree with, add your own. That means writing to a
  repo you own.
- Every machine and project should sync from a repo **you** control, not from
  someone else's `main` changing under you.

**With a terminal** — clone *your fork* (not this repo, so `sync.sh` follows
the repo you can push to):

```sh
git clone https://github.com/YOUR-USERNAME/dotfiles-ai ~/dotfiles-ai
~/dotfiles-ai/install.sh
```

This concatenates the modules and inserts them as a clearly-marked managed
block in the user-level instruction file of each AI CLI it detects on your
machine (detection = the tool's config directory exists). Use
`./install.sh --all` to write every target regardless.

**Installing only some modules.** `./install.sh --list` prints every module
with its one-line summary; `--only git,testing` or `--except repo-config`
installs a subset. The choice is remembered in
`~/.local/state/dotfiles-ai/modules`, because `sync.sh` re-runs the installer
unattended and a selection that lasted until the next daily sync would be a
trap. `--all-modules` forgets it. The durable way to curate is still to delete
modules you don't want from `defaults/` in your fork — the saved selection is
for keeping a subset on one machine without changing the repo.

Re-running the script replaces the managed block in place (a `.bak` backup is
saved), so anything you keep in those files outside the block is untouched.

**Without a terminal** — for cloud agents (Claude Code on the web, Codex
cloud) and settings-UI tools, copy [`INSTRUCTIONS.md`](INSTRUCTIONS.md) out of
your fork on github.com and paste it where the tool reads instructions. No
clone, nothing installed; see the next section.

**Claude Code on the web, every session** — configure the environment once
instead of every project; see below.

**Web chat (Claude, ChatGPT, Gemini)** — paste
[`INSTRUCTIONS-brief.md`](INSTRUCTIONS-brief.md) into each provider's
persistent instructions field. The full block is far too large for those
fields; the condensed one fits all of them.

The [website has the click-by-click guide](https://mchelen.github.io/dotfiles-ai/#install)
for each environment, with screenshots.

## Claude Code on the web: one setup script, every session

A cloud session runs in a fresh VM, so nothing from your machine is there —
but the session's *environment* can carry a **setup script**: Bash that runs
as root **before Claude Code launches**, whose writes to disk persist. Point
it at your fork and it does what you'd do on a laptop, leaving the block in
the container's `~/.claude/CLAUDE.md`. Every repo you open in that
environment, nothing committed to any project, no effect on collaborators.

At `claude.ai/code`, click the cloud icon showing the current environment's
name, hover the environment, click the settings icon, and put this in the
**Setup script** field:

```sh
#!/bin/bash
# dotfiles-ai: user-level defaults for every session in this environment
git clone --depth 1 https://github.com/YOUR-USERNAME/dotfiles-ai /opt/dotfiles-ai || true
mkdir -p "$HOME/.claude"
/opt/dotfiles-ai/install.sh || true
```

The `mkdir` matters — `install.sh` only writes a tool's file when that tool's
config directory exists, and a fresh container has none. The `|| true` guards
matter too: a setup script that exits non-zero fails the whole session.
Confirm it worked by starting a *new* session (resumes don't re-run it) and
asking Claude to `cat ~/.claude/CLAUDE.md`.

Notes:

- **Cached.** The script runs on the first session in an environment; later
  sessions start from a filesystem snapshot. It re-runs when you edit the
  script, change the allowed hosts, or after roughly seven days — so change a
  character in the script to pull in module edits immediately.
- **Keep the repo public.** A private fork would need a token in the clone
  URL, and environment variables are not a secrets store. `github.com` is on
  the default *Trusted* network allowlist, so a public clone needs no extra
  configuration.
- **Teams.** Owners/admins on Team and Enterprise plans can put the same
  script in an organization-shared environment (admin settings → *Cloud
  environments*).
- **Always-fresh alternative.** A `SessionStart` hook in a repo's
  `.claude/settings.json` runs every session including resumes, cloud and
  local — no cache to bust — but it's committed, so it's per-project and your
  collaborators run it too.

## `INSTRUCTIONS.md` (generated)

[`INSTRUCTIONS.md`](INSTRUCTIONS.md) at the repo root is every module in
`defaults/` assembled into the same marker-delimited block `install.sh`
writes. It exists so the defaults can be used with no terminal at all: open it
in your fork, click **Copy raw file**, and paste it into a project's
`AGENTS.md` through the GitHub web editor, or into a settings field like
Cursor's *User Rules*.

[`INSTRUCTIONS-brief.md`](INSTRUCTIONS-brief.md) is the condensed companion:
one line per module, taken from each module's bold thesis sentence. It exists
because web chat instruction fields are size-capped — Claude project
instructions around 8,000 characters, ChatGPT custom instructions 5,000 on
paid plans and 1,500 on Free/Go — while the full block is ~15,000. The brief
is ~1,435, so it fits all three, with roughly one module of headroom before
the smallest cap is missed.

Both are generated — never edit them by hand. The
[`generate-instructions` workflow](.github/workflows/generate-instructions.yml)
runs `install.sh --print` and `install.sh --brief` and commits the results
whenever `defaults/**` changes on `main`. CI rather than a local pre-commit hook is the
point: a module edited in the browser has no local hook to run, and the
no-terminal path only works if this file is always current.

## Keeping copies in sync

The copies of the defaults can drift apart, each refreshed differently:

| Direction | How | Effort |
|---|---|---|
| Your fork ← upstream | GitHub's **Sync fork** button | one click, no terminal |
| Your machines ← your fork | `sync.sh` | automatic, daily |
| Cloud sessions ← your fork | Setup script re-runs when the environment cache rebuilds | edit the script to force it |
| Project repos ← your fork | Re-copy `INSTRUCTIONS.md`, replace the block | manual |

### Your fork ← upstream

On your fork's **Code** tab, click **Sync fork** in the banner above the file
list (it appears when upstream is ahead), then **Update branch**. No terminal,
no remotes to configure. If you've edited the same files GitHub offers
*Discard commits* instead — don't take it; merge or cherry-pick from a clone.
`INSTRUCTIONS.md` is regenerated by CI from whatever `defaults/` holds after
the sync, so it stays consistent with your modules.

### Your machines ← your fork

Installed blocks are copies — they only change when `install.sh` runs. Two
pieces of automation keep them current, so the flow is: edit `defaults/` on
any machine → merge to your fork's `main` → every other machine picks it up on
its next shell start (or next `git pull`).

**1. Shell startup** — add to `~/.zshrc` / `~/.bashrc`:

```sh
[ -x "$HOME/dotfiles-ai/sync.sh" ] && "$HOME/dotfiles-ai/sync.sh" --auto
```

`sync.sh --auto` pulls the latest `main` and re-runs the installer, at most
once per day (override with `DOTFILES_AI_SYNC_INTERVAL`, in seconds). It's
completely silent when there's nothing new, when offline, or when throttled,
so it doesn't clutter shell startup; it prints only when defaults actually
changed.

**2. Manual pulls** — a post-merge hook (managed by the pre-commit
framework, see below) re-runs `install.sh` after any `git pull` in this
repo, so installed files never lag the checkout.

### Cloud sessions ← your fork

The setup script clones your fork on each run, so it picks up whatever `main`
holds at that moment — but the run itself is snapshot-cached rather than
repeated per session. Edits reach new cloud sessions when the cache rebuilds
(script change, allowed-hosts change, or ~7 days), and immediately if you
change a character in the script. Resuming a session never re-runs it.

### Project repos ← your fork

A block committed into a project's `AGENTS.md` / `CLAUDE.md` is a snapshot in
*that* repo's history; nothing updates it automatically, and there's no
upstream-sync bot for it today. Those files are shared with collaborators, so
refreshing one is a deliberate act:

1. Open `INSTRUCTIONS.md` in your fork, click **Copy raw file**.
2. Open the project's `AGENTS.md` (the `CLAUDE.md` import needs no changes),
   click the pencil icon.
3. Select from the `<!-- BEGIN dotfiles-ai … -->` line through the
   `<!-- END dotfiles-ai -->` line, inclusive, and delete it.
4. Paste the fresh block in its place.
5. **Commit changes… → Commit changes**.

The markers are what make this safe: the project's own instructions, outside
the block, are untouched. From a clone, `./install.sh --print` gives the same
text.

## Tests

```sh
./test.sh
```

The acceptance scenarios from [`specs/001-user-level-install`](specs/001-user-level-install/spec.md),
executable: each case runs `install.sh` against a throwaway `HOME` and checks
the result. No framework — bash and `mktemp`. CI runs it on every push and pull
request.

## Guarding against leaked secrets

This repo practices what [`defaults/secrets.md`](defaults/secrets.md)
preaches, in three layers:

1. **Pre-commit** — the standard [pre-commit](https://pre-commit.com)
   framework ([`.pre-commit-config.yaml`](.pre-commit-config.yaml)) runs
   the official gitleaks hook plus `detect-private-key` and
   `detect-aws-credentials` on every commit. PII patterns (SSN, payment
   card numbers) extend gitleaks' built-in rules via
   [`.gitleaks.toml`](.gitleaks.toml). Setup per machine (`sync.sh` does
   this automatically when `pre-commit` is on the PATH):

   ```sh
   pipx install pre-commit   # or: brew install pre-commit
   pre-commit install --hook-type pre-commit --hook-type post-merge
   ```

   False positives get a `gitleaks:allow` comment on the line.
2. **CI** — [`.github/workflows/secret-scan.yml`](.github/workflows/secret-scan.yml)
   runs the gitleaks action on every push and PR, catching anything that
   slipped past (or bypassed) the local hook.
3. **Platform** — *GitHub secret scanning* and *push protection*, declared
   in the Terraform config below. GitHub then blocks pushes containing
   recognized provider tokens server-side.

## Repo settings as code

Repository settings live in [`infra/main.tf`](infra/main.tf) (official
Terraform GitHub provider) instead of the web UI: description, merge
policy, Pages (published by the `deploy-pages` workflow), vulnerability
alerts, and secret
scanning with push protection. An `import` block adopts the existing repo,
so the first apply changes settings without recreating anything.

**Applied automatically in CI**: the
[`repo-settings` workflow](.github/workflows/repo-settings.yml) runs
`terraform apply` whenever `infra/` changes on `main`, using the stateless
import pattern (the import block re-adopts the repo each run, so no
Terraform backend is needed). One-time setup, because Actions' built-in
`GITHUB_TOKEN` cannot administer repo settings:

1. [Create a fine-grained PAT](https://github.com/settings/personal-access-tokens/new)
   scoped to this repo with **Administration: read & write**
2. Save it as an Actions secret named `REPO_ADMIN_TOKEN`
   (Settings → Secrets and variables → Actions)

Until the secret exists the workflow skips with a notice. Manual apply
still works too:

```sh
export GITHUB_TOKEN=$(gh auth token)   # needs admin on the repo
cd infra && terraform init && terraform apply
```

To change a setting, edit the `.tf` file and merge — don't flip it in
the UI and let the code drift.

## Specs for this repo

The [`specification`](defaults/specification.md) module asks every project to
keep intended behavior written down in a standard format, so this repo does
too. [`specs/`](specs/) holds one [Spec Kit](https://github.com/github/spec-kit)
`spec.md` per capability — [the installer](specs/001-user-level-install/spec.md),
[machine sync](specs/002-machine-sync/spec.md), and
[the generated `INSTRUCTIONS.md`](specs/003-generated-instructions/spec.md) —
with project-wide principles in
[`.specify/memory/constitution.md`](.specify/memory/constitution.md).

They were written from the code rather than before it, so there are no
`plan.md` / `tasks.md` alongside them; [`specs/README.md`](specs/README.md)
explains that choice. From here they're the contract: behavior changes revise
the spec in the same pull request.

## Usage by tool

There are three delivery mechanisms, depending on what a given tool reads:

1. **User-level file** — `install.sh` writes it for you; applies to every
   project on the machine.
2. **Settings UI** — paste `INSTRUCTIONS.md` (or the output of
   `./install.sh --print`) into the tool's rules/instructions setting.
3. **Repo file** — commit the block (or a subset of modules) into the
   project's `AGENTS.md`; needed for cloud/web agents that only see the repo.
   Copy it from `INSTRUCTIONS.md` in your fork — no local clone required.
   Claude Code reads `CLAUDE.md` rather than `AGENTS.md`, so add a one-line
   `CLAUDE.md` containing `@AGENTS.md` to point it at the same block.

| Tool | Surface | Where the defaults go | Mechanism |
|---|---|---|---|
| **Claude Code** | CLI, desktop app, IDE extensions | `~/.claude/CLAUDE.md` (user memory) | `install.sh` ✅ |
| **Claude Code** | Web (claude.ai/code) | The repo's `AGENTS.md`, plus a `CLAUDE.md` containing `@AGENTS.md` — Claude Code reads `CLAUDE.md`, not `AGENTS.md` | repo file |
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
- **Repo files**: for cloud agents, paste `INSTRUCTIONS.md` (or the `--print`
  output) into the project's `AGENTS.md` (plus a `CLAUDE.md` importing it with
  `@AGENTS.md`, which is what Claude Code reads), or copy just the modules
  that matter for that project. Keep in mind those files are shared with collaborators —
  personal preferences you don't want to impose on others belong at the user
  level.
- Tool locations change; if a tool ignores its file, check that tool's
  current docs for where user instructions live.

## Adding your own defaults

1. Drop a new `.md` file in `defaults/` — one topic per file, phrased as
   direct instructions to the assistant. Open it with a **bold thesis
   sentence** under the heading; that single line is what feeds
   `INSTRUCTIONS-brief.md`, and generation fails loudly if it's missing. If it belongs to one of the four
   categories above, add it to that table in this README. (Adding or editing
   a module from the GitHub web editor works just as well.)
2. Re-run `./install.sh` on each machine — or let `sync.sh` do it. Once the
   change reaches `main`, CI regenerates `INSTRUCTIONS.md` for the
   no-terminal paths.

Keep modules short and unconditional enough to apply everywhere; anything
that only applies to one project belongs in that project instead.
