<!-- BEGIN dotfiles-ai (managed block, edit in the dotfiles-ai repo) -->
# Architecture documentation

- Every project keeps an `ARCHITECTURE.md` at the repo root: a high-level
  description of the code — major components, how they fit together, and key
  data flows — including Mermaid diagrams for structure and flows.
- Keep it current: when a change adds, removes, or rewires a component,
  update `ARCHITECTURE.md` in the same change. If it doesn't exist yet,
  create it as part of the first substantial change.
- Stay high level: components and boundaries, not function-by-function
  detail. If the diagram needs updating for small edits, it's too detailed.

# Code style

- Match the existing style of the codebase over any personal or general default.
- Prefer the smallest change that solves the problem; avoid opportunistic
  refactors unless I ask.
- Don't add comments that narrate what the code does; comment only non-obvious
  constraints or reasoning.
- Don't add new dependencies for something a few lines of code can do.
  If a dependency is genuinely warranted, say so and why before adding it.

# Communication

- Lead with the answer or outcome, then supporting detail.
- If something I asked for seems like a bad idea, say so before doing it —
  a one-line "heads up, X might be better because Y" is enough.
- When you're unsure about intent, ask one focused question rather than
  guessing and building the wrong thing.
- Tell me what you *didn't* do: skipped steps, failing tests, known gaps.
  Don't present partially working results as done.

# Offloading mechanical work

Mechanical work belongs in a command, not in your context. When a shell
command, script, or CI job produces the same answer, run it instead of loading
the material and working it out yourself — it's cheaper, it's reproducible, and
it leaves context for the parts that actually need thought.

- **Query, don't read.** Search, filter, count, and compare with the tools built
  for it — `grep`, `jq`, `diff`, `wc` — rather than reading a large file or a
  large command output to find a small part of it.
- **Ask for the answer, not the transcript.** Prefer flags that narrow at the
  source (`--json` with a filter, `--stat`, `--name-only`, `-o`, `-q`) over
  printing everything and picking through it.
- **Make checks self-reporting.** A verification script should print a verdict —
  expected versus actual — not output for me to eyeball.
- **Batch.** Independent commands go in one call, not one round trip each.
- **If it has to hold every time, put it in CI.** A check you would otherwise
  repeat by hand every session belongs in a workflow.

Don't offload when it costs correctness:

- **Judgment doesn't offload.** Reviewing code, weighing an approach, deciding
  whether wording is right — a command can find candidates, it can't decide.
  Read the code you are reasoning about.
- **Don't write a fragile parser to avoid a short read.** If getting the script
  right is harder than reading the thing, read the thing.
- **Don't trust output you can't sanity-check.** A clever one-liner whose result
  you have no way to verify is worse than the slow, obvious path.
- **Keep the evidence that matters.** When something fails I want the actual
  failure output, not a summarized verdict.
- **Never quietly sample.** If you filtered, truncated, or checked only part of
  something, say so. A partial check reported as a complete one is worse than
  no check at all.

# Feature development workflow

When I ask for a new feature or a significant change (as opposed to a bug fix,
small tweak, or something I've already specified in detail):

- Do **not** jump straight into implementation.
- First give me something concrete to react to. Pick whichever fits the task:
  - **Mockup** — an ASCII sketch, quick HTML page, or description of the UI/UX
  - **Demo / spike** — a minimal throwaway version that shows the core idea working
  - **Options** — 2–3 approaches with trade-offs and a recommendation
  - **Direction** — a short proposal: approach, affected files, data model, risks
- Wait for my confirmation or feedback before writing production code.

Skip this ceremony when:

- The change is small and unambiguous (rename, typo, obvious bug fix)
- I've explicitly said to just build it
- I've already approved a direction and this is a follow-up within it

# Git

- Never commit or push unless I ask (or I've clearly set up a workflow where
  it's expected).
- Small, focused commits with descriptive messages; don't bundle unrelated
  changes.
- Once work on a branch is complete and pushed, go ahead and open a pull
  request by default — no need to ask first.
- After opening a pull request, keep watching it if the tooling allows:
  respond to review comments and fix CI failures until it's merged or closed.
- Merge pull requests by default once automated checks pass and any required
  reviews are approved — no need to ask first. Don't merge over failing
  checks, missing required approvals, or unresolved discussions.
- Never force-push, rewrite history, or delete branches without explicit
  confirmation.
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

# Project website

- Most projects should have a static website (GitHub Pages or similar)
  covering: what the project is, why it exists, and how to use it.
- Show the project in action. Where real screenshots or live demos aren't
  practical, simulate them — rendered terminal sessions, mocked UI states,
  example output — and label simulated content as such.
- Include a before/after demo showing what the project actually changes:
  the same scenario with and without it, side by side.
- Give install steps for every environment where they differ (local CLI,
  cloud/web, IDE, settings-UI-only tools), not just the common case —
  and say *why* a variant differs, so the reader can generalize.
- Keep the site in the repo (e.g. a `docs/` folder) so it versions with
  the code, and update it alongside user-facing changes.
- Publish via the GitHub Actions Pages path by default: Pages source set
  to "GitHub Actions", with a workflow using `actions/configure-pages`,
  `actions/upload-pages-artifact`, and `actions/deploy-pages` — not the
  legacy deploy-from-branch mode.
- Plain static HTML/CSS is fine; don't introduce a site generator or
  framework unless the project already has one or genuinely needs it.
- Skip the site for internal scratch work, private utilities, or projects
  too small for it to add anything — and ask before publishing anything
  publicly for the first time.

# Repo configuration as code

- GitHub repository settings are managed declaratively, not clicked through
  the web UI. Use the official Terraform GitHub provider
  (`integrations/github`) with an `import` block to adopt the existing
  repo; keep the config in `infra/` in the repo itself.
- Settings that belong in code: description/homepage, feature toggles,
  merge policy, Pages, vulnerability alerts, secret scanning + push
  protection, and branch protection rules once they exist.
- Never commit Terraform state, lock-in tokens, or `*.tfvars` — state
  stays local (or in a proper backend), auth comes from the environment
  (e.g. `GITHUB_TOKEN=$(gh auth token)`).
- Prefer applying in CI on merge to main: a workflow runs the apply using
  the stateless import-block pattern (re-adopt, reconcile, discard state).
  The built-in Actions `GITHUB_TOKEN` cannot administer repo settings, so
  use a least-privilege fine-grained PAT (Administration only, this repo
  only) stored as an Actions secret — and skip gracefully when it's absent.
- When something must change in repo settings, change the `.tf` file and
  apply — don't flip it in the UI and let the code drift. If a UI change
  already happened, reconcile the code to match (or revert) promptly.
- For org-owned repos, prefer the org's existing mechanism if one exists
  (e.g. safe-settings, an infra monorepo) over per-repo Terraform.

# Secrets and sensitive data

- Every repo gets a pre-commit hook that scans staged changes for
  credentials, key material, and PII before they can be committed. Use
  standard tooling — the pre-commit framework with the official gitleaks
  hook (extra rules via `.gitleaks.toml` `[extend]`) — not hand-rolled
  scanners. Set it up as part of the first substantial change.
- Layer the defenses; don't rely on any single one:
  - **pre-commit** — catches secrets before they enter history
  - **CI** — a secret scanner (e.g. the gitleaks action) on every push/PR
  - **platform** — GitHub secret scanning with push protection enabled in
    repo or org settings
- Never weaken or bypass these checks (`--no-verify`, editing patterns)
  without flagging it to me explicitly first.
- A false positive gets an explicit inline allow-marker, not a disabled
  check.
- If a real secret ever reaches history — even briefly, even in a private
  repo — treat it as compromised: rotate it and say so. Deleting the file
  or force-pushing does not un-leak it.

# Specification

For anything beyond a small change, keep a written specification in the repo,
in a standard format, and keep it true. The current format is
[Spec Kit](https://github.com/github/spec-kit).

- **Where it lives:** one directory per feature under `specs/`, holding
  `spec.md` (the intended behavior) and, where the tooling is in use,
  `plan.md` (technical approach) and `tasks.md` (work breakdown).
  Project-wide principles go in `.specify/memory/constitution.md`.
- **The spec is the contract.** It states what the software should do and why
  — behavior, constraints, acceptance criteria — not how the code achieves it.
  Implementation detail belongs in `plan.md`.
- **Keep it current.** When intended behavior changes, revise `spec.md` in the
  same change as the code; never leave it describing behavior that no longer
  exists. Then bring `plan.md` and `tasks.md` back in line with it. Same rule
  as `ARCHITECTURE.md`.
- **Never let them disagree silently.** If you find code that contradicts the
  spec, say so and ask which one is wrong. Don't quietly rewrite the spec to
  match whatever the code happens to do.
- **It pairs with the feature workflow.** For a significant feature the spec,
  or a draft of it, is usually the concrete thing to react to: write it, show
  me, wait for a yes before implementing. Don't chain the generation commands
  straight through to implementation unattended.
- **Tooling:** when a project already has `.specify/`, use its commands —
  `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.tasks`,
  `/speckit.analyze`, `/speckit.implement`, `/speckit.converge`. When it
  doesn't, ask before adding the toolchain: `specify init` reshapes the repo,
  so it isn't a unilateral call, and a hand-written `spec.md` in the same
  shape is fine on its own.

Skip all of this for small, unambiguous changes, one-off scripts, and
throwaway spikes — the same threshold as the feature workflow.

# Testing

- Write tests **before** implementation by default: start from a failing test
  that captures the expected behavior, then write the code to make it pass.
- Show me the failing test run before the fix and the passing run after —
  that's the evidence the test actually exercises the change.
- When fixing a bug, first add a test that reproduces it.
- Test behavior, not implementation details; don't write tests that just
  mirror the code's internals or mock everything into meaninglessness.
- Use the project's existing test framework and conventions. If the project
  has no test setup at all, propose one before introducing it.

Skip test-first when:

- It's a throwaway spike, mockup, or exploration (per the feature workflow)
- The change isn't meaningfully testable (docs, comments, formatting, config)
- I've explicitly said to skip tests

# Tool fallbacks

- If an interactive tool looks stuck — the same prompt keeps reappearing, a
  response never arrives, or I say I answered something you never received —
  stop using that tool and continue in plain text. Say that you're switching
  and why.
- A rejection is not always a refusal. If a tool reports that I declined but I
  say I answered, treat it as lost input rather than a decision, and re-ask in
  plain text.
- Never re-ask through a mechanism that just failed. Two failures of the same
  kind mean change approach, not retry — retrying is what turns one lost
  answer into a loop.
- Known issue behind this rule: dismissing an `AskUserQuestion` card silently
  discards typed free text, and a resolved card can keep re-rendering on
  mobile until the app restarts —
  <https://github.com/anthropics/claude-code/issues/81223>. If either happens,
  fall back to plain text and suggest restarting the app.
- This applies to any tool, not just question prompts: when something fails
  repeatedly, use the simplest thing that works — plain text, a file, a shell
  command — and tell me what you fell back to.
- When a tool failure may have destroyed something I typed, say so explicitly
  instead of quietly proceeding on a guess.

<!-- END dotfiles-ai -->
