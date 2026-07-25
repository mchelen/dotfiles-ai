# Architecture

dotfiles-ai has two moving parts: a set of preference modules and an
installer that assembles them into the instruction files AI coding tools
read at the user level.

```mermaid
flowchart LR
    S["sync.sh --auto<br/>(shell startup, daily)"] -->|"git pull main"| D
    H["post-merge hook<br/>(pre-commit framework)"] -->|"re-run"| I
    S -->|"re-run"| I
    subgraph repo["dotfiles-ai repo"]
        D["defaults/*.md<br/>one module per topic"]
        I["install.sh"]
    end
    D -->|"concatenated into a<br/>marker-delimited managed block"| I
    I -->|"insert / replace block<br/>(if tool detected)"| C["~/.claude/CLAUDE.md<br/>(Claude Code)"]
    I -->|"insert / replace block<br/>(if tool detected)"| X["~/.codex/AGENTS.md, ~/.copilot/…,<br/>~/.gemini/…, ~/.qwen/…,<br/>opencode, goose"]
    I -->|"--print"| P["stdout → paste into<br/>UI-only tools (e.g. Cursor)"]
```

## Components

- **`defaults/`** — the content: flat `.md` files, one self-contained,
  tool-agnostic preference module each, written as direct instructions to
  an assistant. Modules are independent; the installer includes all of them
  in filename order. Modules are also grouped into four documentation
  categories — collaboration, craft, delivery, documentation — but that
  grouping lives in the README and the website only, deliberately not in
  the directory layout, so adding a module stays a one-file drop.
- **`install.sh`** — the delivery mechanism. It concatenates the modules
  between `BEGIN`/`END` HTML-comment markers and inserts that block into
  each target file. Re-runs replace only the managed block (backing up the
  file first), so user content outside the markers is never touched.
  Targets are a plain list in the script — adding a tool means adding a
  path there. A target is skipped unless its tool's config directory
  already exists (`--all` overrides), so only tools actually in use get
  instruction files.
- **`docs/`** — the project website (static HTML/CSS, no generator),
  published to GitHub Pages by **`.github/workflows/deploy-pages.yml`**
  (`actions/deploy-pages`) on merges to `main` that touch `docs/`.
  Terminal output shown there is simulated and labeled as such.
- **`sync.sh`** — propagation. Pulls the latest `main` (fast-forward only)
  and re-runs the installer. In `--auto` mode (meant for shell startup) it
  throttles to one attempt per day via a stamp file in
  `~/.local/state/dotfiles-ai/`, tracks the last-installed commit so a
  fresh machine installs on first run, and stays silent when offline or
  already current. It also runs `pre-commit install` (when available) so
  the framework's commit and post-merge hooks are active on the machine.
- **`.pre-commit-config.yaml`** — secret/PII gate on every commit via the
  standard pre-commit framework: official gitleaks hook (custom PII rules
  extend the defaults in **`.gitleaks.toml`**), `detect-private-key`,
  `detect-aws-credentials`, plus a local post-merge hook that re-runs
  `install.sh` after pulls (replacing the old `core.hooksPath` approach).
  Backed up by **`.github/workflows/secret-scan.yml`**, which runs
  gitleaks in CI on every push/PR, and by GitHub secret scanning + push
  protection in repo settings.
- **`infra/`** — GitHub repository settings as code (Terraform, official
  GitHub provider): description, merge policy, Pages source, vulnerability
  alerts, secret scanning + push protection. An `import` block adopts the
  existing repo; state stays local and is gitignored. Applied by
  **`.github/workflows/repo-settings.yml`** on merges to `main` touching
  `infra/` (stateless: re-import, reconcile, discard state), using a
  fine-grained admin PAT in the `REPO_ADMIN_TOKEN` secret; skips with a
  notice when the secret is absent.

## Key invariant

The generated block in target files is disposable: the source of truth is
always `defaults/`. Edits belong in this repo, followed by a re-run of
`install.sh` — never in the installed files directly.
