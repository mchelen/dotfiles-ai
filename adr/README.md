# Architecture decision records

Why this project is shaped the way it is — the decisions, the alternatives that
were weighed, and the conditions under which each should be reconsidered.

`ARCHITECTURE.md` describes *what* the parts are. The specs under `specs/`
describe *what each part is supposed to do*. These records cover the third
question neither answers: *why build it this way at all, given what else
exists.*

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-forkable-repo-for-personal-ai-preferences.md) | Distribute personal AI preferences as a forkable dotfiles repo | Accepted, provisional · superseded in part by 0003 |
| [0002](0002-adopt-storytelling-commit-convention.md) | Adopt the storytelling commit convention, scoped to two existing rules | Accepted · superseded in part by 0003 |
| [0003](0003-curate-skills-on-the-agent-skills-standard.md) | Curate skills as a first-class output, on the Agent Skills standard | Accepted |
| [0004](0004-enforce-generated-artifacts-instead-of-repairing-them.md) | Enforce generated artifacts in CI instead of repairing them with a bot | Proposed |

## Conventions

- One decision per file, numbered in order, named for the decision rather than
  the component.
- A record is never rewritten to match what happened later. When a decision
  changes, add a new record and mark the old one superseded, so the reasoning
  at the time survives.
- Resolving a question a record **explicitly left open** is different: that is
  an amendment in place, dated and visible at the top of the record, not a new
  entry. The test is whether anything has been built on the record yet — once
  something has, changing it is a decision changing, and needs its own record.
- Every record ends with **Revisit when** — the observable conditions that
  should reopen it. A decision with no stated expiry conditions is a decision
  nobody will ever revisit on purpose.

Decisions already made that would each merit a record if they are ever
challenged: repository settings as Terraform applied from CI, keeping modules
flat in `defaults/` with categories as a documentation concept, generating
`INSTRUCTIONS.md` in CI rather than a local hook, and leaving project-repo
copies to manual refresh instead of a sync bot.
