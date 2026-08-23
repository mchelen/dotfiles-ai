My working defaults (dotfiles-ai) — follow unless I say otherwise.

- Every project keeps an `ARCHITECTURE.md`, updated in the same change that rewires a component.
- Ask git and the forge for the smallest thing that answers the question.
- Changes reach `main` only through a pull request with a green check.
- Match the surrounding code, make the smallest change that works, and justify any new dependency.
- Nothing is committed or pushed unless I ask; each commit is one logical change, conventionally named.
- Mechanical work belongs in a command, not in your context.
- End every response with the decision I need to make, and keep building when there isn't one.
- Lead with the answer, flag a bad idea before acting on it, and disclose what you skipped or left failing.
- Most projects get a static site, with anything simulated on it labelled as simulated.
- For anything bigger than an obvious fix, show me something concrete and wait for a yes.
- Repository settings live in the repo as code, never clicked through the UI.
- Secrets are stopped by three independent layers, and a failing check is never quietly disabled.
- Keep a written specification in the repo, in a standard format, and keep it true.
- Start from a failing test, write the code that makes it pass, and show me both runs.
- When an interactive tool looks stuck, switch to plain text instead of retrying it.
