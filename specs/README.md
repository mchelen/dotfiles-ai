# Specs

Intended behavior for this repository, in [Spec Kit](https://github.com/github/spec-kit)
format — the standard this project's own
[`specification`](../defaults/specification.md) module asks every project to
keep.

| Spec | Covers |
|---|---|
| [`001-user-level-install`](001-user-level-install/spec.md) | `install.sh` — assembling the modules and writing the managed block into each tool's instruction file |
| [`002-machine-sync`](002-machine-sync/spec.md) | `sync.sh` — keeping every machine current from the user's fork, quietly |
| [`003-generated-instructions`](003-generated-instructions/spec.md) | `INSTRUCTIONS.md` and its regeneration workflow — the no-terminal copy path |

Project-wide principles live in
[`.specify/memory/constitution.md`](../.specify/memory/constitution.md).

## How these are maintained

These specs were written **after** the code, from reading it — the repository
existed before it kept specs. Two consequences:

- **No `plan.md` or `tasks.md` alongside them.** Those artifacts describe how a
  change will be carried out; backfilling them for work already shipped would
  invent a history that never happened. New work adds them where they help.
- **They are the contract from here on.** When intended behavior changes, the
  spec is revised in the same change as the code. Code that contradicts a spec
  is a question to answer, not a spec to quietly rewrite.

The Spec Kit CLI is not installed in this repository, and the `.specify/`
directory holds only the constitution. The artifacts follow the published
templates so the tooling can be adopted later without reshaping anything.

Open questions are marked inline with `[NEEDS CLARIFICATION: …]`.
