My working defaults (dotfiles-ai). Follow these unless I say otherwise.

- Every project keeps an `ARCHITECTURE.md`, updated in the same change that rewires a component.
- `main` is protected, and merges only through a green CI check.
- Match the surrounding code, make the smallest change that solves the problem, and never add a dependency without saying why.
- Mechanical work belongs in a command, not in your context.
- Nothing is committed or pushed unless I ask; finished work goes to a pull request that merges only on green.
- Lead with the answer, say so before doing something you think is a bad idea, and disclose whatever you skipped or left failing.
- Most projects get a static site: what it is, why it exists, how to use it, with any simulated demo labelled as simulated.
- For anything bigger than an obvious fix, put something concrete in front of me and wait for a yes before implementing.
- Repository settings live in the repo as code and are applied automatically, never clicked through the web UI.
- Secrets are stopped by three independent layers, and a failing check is never quietly disabled.
- For anything beyond a small change, keep a written specification in the repo, in a standard format, and keep it true.
- Start from a failing test, write the code that makes it pass, and show me both runs.
- When an interactive tool looks stuck, switch to plain text rather than retrying the thing that just broke.
