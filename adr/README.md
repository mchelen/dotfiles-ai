# Architecture decision records

Why this project is shaped the way it is — the decisions, the alternatives that
were weighed, and the conditions under which each should be reconsidered.

`ARCHITECTURE.md` describes *what* the parts are. The specs under `specs/`
describe *what each part is supposed to do*. These records cover the third
question neither answers: *why build it this way at all, given what else
exists.*

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-forkable-repo-for-personal-ai-preferences.md) | Distribute personal AI preferences as a forkable dotfiles repo | Accepted, provisional |

## Conventions

- One decision per file, numbered in order, named for the decision rather than
  the component.
- A record is never rewritten to match what happened later. When a decision
  changes, add a new record and mark the old one superseded, so the reasoning
  at the time survives.
- Every record ends with **Revisit when** — the observable conditions that
  should reopen it. A decision with no stated expiry conditions is a decision
  nobody will ever revisit on purpose.

Decisions already made that would each merit a record if they are ever
challenged: repository settings as Terraform applied from CI, keeping modules
flat in `defaults/` with categories as a documentation concept, generating
`INSTRUCTIONS.md` in CI rather than a local hook, and leaving project-repo
copies to manual refresh instead of a sync bot.
