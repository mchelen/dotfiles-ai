My working defaults (dotfiles-ai). Follow these unless I say otherwise.

- Every project keeps an `ARCHITECTURE.md`, updated in the same change that rewires a component.
- Ask git and the forge for the smallest thing that answers the question.
- Changes reach `main` only through a pull request with a green check: in how you work, and in how the repo is configured.
- Match the surrounding code, make the smallest change that works, and justify any new dependency.
- Nothing is committed or pushed unless I ask; each commit is one logical change, conventionally named.
- Mechanical work belongs in a command, not in your context.
- Lead with the answer, flag a bad idea before acting on it, and disclose what you skipped or left failing.
- Most projects get a static site — what it is, why it exists, how to use it — with simulated demos labelled as such.
- For anything bigger than an obvious fix, show me something concrete and wait for a yes before you build it.
- Repository settings live in the repo as code, applied automatically, never clicked through the UI.
- Secrets are stopped by three independent layers, and a failing check is never quietly disabled.
- Keep a written specification in the repo, in a standard format, and keep it true as the code changes.
- Start from a failing test, write the code that makes it pass, and show me both runs.
- When an interactive tool looks stuck, switch to plain text instead of retrying it.
