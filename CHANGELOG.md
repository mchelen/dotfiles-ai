# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com).
This project is not versioned — the defaults are meant to be forked and
edited, so there is nothing to release. Sections are dated instead.

## [Unreleased]

### Added

- `install.sh --project [DIR]` writes the selected modules into a project
  repository's `AGENTS.md`, with a `CLAUDE.md` that imports it, so preferences
  that belong to a repo reach everyone working on it. The quick start offers
  this alongside the machine-level install, once you have chosen your modules.
  It is a snapshot — nothing refreshes a file in a repo you share.
- A `changelog` module: every project keeps a `CHANGELOG.md` written for
  readers rather than generated from the commit log, published on the
  project's website rather than left in the source tree.
- This file, and its page on the site.

## 2026-08-23

### Added

- Branch protection on `main`, declared in `infra/`: pull requests only, the
  `test` check required, administrators included, no bypass list.
- `sync.sh` is covered by tests for the first time — fifteen checks against a
  throwaway git remote, making every requirement in its spec executable.
- The weekly repository-settings check: `repo-settings` now runs Mondays in
  check-only mode, reporting drift without applying it.
- A `decision-handoffs` module: every response ends with the decision you need
  to make, its options and their costs; where there is nothing to decide, work
  continues rather than waiting.

### Fixed

- `sync.sh --auto` printed five lines of git diagnostics at the prompt on
  every shell start while offline. `--quiet` suppresses progress, not
  failures. Automatic mode now goes on the exit status alone; manual mode
  still shows them.
- Generated artifacts could go stale: `INSTRUCTIONS.md` and
  `INSTRUCTIONS-brief.md` were never checked against `defaults/`, so a change
  that rebuilt the site but not the block passed. All three are checked now.

### Changed

- Generated artifacts are regenerated in the change that edits a module and
  enforced by CI, instead of being repaired afterwards by a workflow pushing
  to `main`. **Editing a module entirely in the browser no longer completes on
  its own** — the change fails its check until someone with a shell or an
  agent regenerates. Every read path is unaffected.
- The Settings GitHub App is now the default mechanism in the `repo-config`
  module, with Terraform the alternative: the app is easier to set up,
  Terraform reaches settings the app has no keys for (Pages, secret scanning,
  push protection).

### Removed

- The `generate-instructions` workflow, and with it the last thing that pushed
  to `main`.

## 2026-08-22

### Added

- Module selection: `install.sh --list`, `--only`, `--except`, and
  `--all-modules`. A chosen subset is remembered, because `sync.sh` re-runs
  the installer unattended and a selection that lasted a day would be a trap.
- The quick-start snippet asks which modules you want before applying
  anything, and says plainly that following it means trusting this repo's
  author.
- A `ci-gated-main` module, later merged with the pull-request workflow into
  one record of how changes reach the default branch.

### Changed

- Every module card on the website now carries the module's **exact text**,
  copied verbatim by `build-site.sh`, instead of a hand-written paraphrase
  that drifted.
- Modules renamed for what they achieve: `communication` became
  `honest-reporting`, `feature-workflow` became `propose-before-building`, and
  the `git` module was split into `commit-conventions`, `cheap-git-queries`,
  and the merged `ci-gated-main`.
- The condensed block was cut from 1,446 to 1,294 characters, and the
  1,500-character floor it has to fit is now enforced by `install.sh --brief`
  and the test suite rather than remembered.

### Fixed

- The managed block was not replaced when a marker line had been edited by
  hand: detection matched loosely, removal matched exactly, and a trailing
  space produced a second block. Writing the reproduction surfaced a worse
  defect — a `BEGIN` with no `END` deleted everything below it and exited
  zero. Both are fixed, and the run now aborts without touching the file.

## 2026-07-26

### Added

- `INSTRUCTIONS-brief.md`, a condensed one-line-per-module block for web chat
  instruction fields, which cap out well below the full block.
- Architecture decision records in `adr/`, starting with why the project is a
  forkable repo at all.

### Changed

- Blocks committed into project repositories target `AGENTS.md`, with a
  `CLAUDE.md` that imports it — Claude Code reads `CLAUDE.md`, not
  `AGENTS.md`.
- Commits follow the storytelling convention: atomic units, conventional
  prefixes, and history reshaped on the branch rather than on `main`.

## 2026-07-25

### Added

- The fork-first install guide, including a path that needs no terminal at
  all, and a per-environment walkthrough for Claude Code on the web.
- `specification` and `compute-offload` modules, and `specs/` describing this
  project's own behaviour in Spec Kit format.
- `tool-fallbacks`: when an interactive tool looks stuck, drop to plain text.

## 2026-07-21

### Added

- The project website, published to GitHub Pages.
- `sync.sh`, with shell-startup auto-sync and a post-merge hook.
- Layered secret and PII protection, and the `secrets` module.
- Repository settings as code, applied from CI.
- Install targets for Copilot CLI, Gemini CLI, Qwen Code, OpenCode, and Goose.

## 2026-07-16

### Added

- The first modules and `install.sh`.
