# Specification

**For anything beyond a small change, keep a written specification in the repo,
in a standard format, and keep it true.**

The current format is
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
