# Feature Specification: Generated INSTRUCTIONS.md

**Feature Branch**: n/a — retroactive spec for behavior already shipped in
`INSTRUCTIONS.md` and `.github/workflows/generate-instructions.yml`

**Created**: 2026-07-25

**Status**: Active (describes current intended behavior)

**Input**: Make the assembled block available to someone who has only a browser —
no clone, no shell — and keep that copy current automatically.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Use the defaults with no terminal (Priority: P1)

Someone who works entirely in the browser opens one file in their fork, copies
it, and pastes it where their tool reads instructions — a project's `CLAUDE.md`
through the web editor, or a settings field.

**Why this priority**: It is the only path available to cloud-agent and
settings-UI users. Without it, those users cannot adopt the defaults at all.

**Independent Test**: From a browser alone, with no local clone, get the current
assembled block onto the clipboard.

**Acceptance Scenarios**:

1. **Given** a fork of the repository, **When** the user opens the generated file
   at the repository root, **Then** it contains the complete assembled block,
   including both markers, and nothing else.
2. **Given** that file is open on the hosting site, **When** the user uses the
   copy-raw control, **Then** the clipboard holds text that can be pasted
   directly into an instruction file with no editing.
3. **Given** the pasted block, **When** the user later refreshes it, **Then** the
   markers let the old block be replaced without touching surrounding content.

---

### User Story 2 - Edit a module in the browser and stay current (Priority: P1)

A module is edited through the web editor, with no local checkout anywhere in the
loop. The generated file updates itself.

**Why this priority**: Equal to the first — a copy path that goes stale is worse
than none, because the user believes they are current when they are not.

**Independent Test**: Edit a module through the web editor, commit to the default
branch, and confirm the generated file reflects the change without any local
action.

**Acceptance Scenarios**:

1. **Given** a commit on the default branch that changes any module, **When** the
   regeneration runs, **Then** the generated file is rewritten from the modules
   and committed back.
2. **Given** a commit that leaves the generated file already correct, **When** the
   regeneration runs, **Then** it records that nothing was needed and makes no
   commit.
3. **Given** a change to the assembly logic itself, **When** it lands on the
   default branch, **Then** the generated file is regenerated too.

---

### User Story 3 - Trust the file without checking it (Priority: P2)

Anyone reading the generated file can rely on it matching the modules, without
comparing it by hand.

**Why this priority**: Confidence is the whole value of a generated artifact; a
file people feel they must verify is a file they will stop using.

**Independent Test**: For any commit on the default branch, regenerate and
confirm the result is identical to the committed file.

**Acceptance Scenarios**:

1. **Given** any commit on the default branch, **When** the block is assembled
   from the modules at that commit, **Then** the result is byte-identical to the
   committed generated file.
2. **Given** the generated file has been edited by hand, **When** the next
   regeneration runs, **Then** the hand edit is overwritten.

---

### Edge Cases

- **Nothing changed.** The regeneration makes no commit at all, rather than an
  empty one.
- **Regeneration must not trigger itself.** The commit it makes touches only the
  generated file, which is not among the paths that start the process.
- **Two changes in quick succession.** Regeneration runs are serialized so the
  later one is not cancelled and does not race the earlier one's commit.
- **The file is edited in the same pull request as a module.** The result is the
  same either way: correct at merge time, and the regeneration finds nothing to
  do.
- **A fork with the automation disabled.** The generated file stays at whatever
  the last regeneration produced. [NEEDS CLARIFICATION: should the install guide
  tell fork owners to check that the workflow is enabled?]

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The repository MUST contain, at its root, a generated file holding
  exactly the assembled block that the installer would print.
- **FR-002**: That file MUST be usable by copy and paste with no editing: no
  preamble, no trailing commentary, both markers present.
- **FR-003**: The file MUST be regenerated whenever the modules or the assembly
  logic change on the default branch.
- **FR-004**: Regeneration MUST commit the result only when it differs from what
  is already committed.
- **FR-005**: Regeneration MUST run in continuous integration, not as a local
  pre-commit step, so that changes made without a local checkout are covered.
- **FR-006**: The file MUST never be authored or corrected by hand; the modules
  are the only input.
- **FR-007**: Regeneration MUST NOT retrigger itself.
- **FR-008**: Concurrent regenerations MUST NOT race each other.

### Key Entities

- **Generated instructions file**: the repository-root copy of the assembled
  block, the artifact every no-terminal path reads.
- **Regeneration workflow**: the automation that rebuilds that file from the
  modules and commits the difference.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A browser-only user can obtain the current block in two clicks —
  open the file, copy raw — with no clone and nothing installed.
- **SC-002**: For every commit on the default branch, the committed file matches
  a fresh assembly of the modules at that commit.
- **SC-003**: A module edited entirely in the browser is reflected in the
  generated file without any human action.
- **SC-004**: A change that leaves the file correct produces no commit and no
  noise in history.

## Assumptions

- The hosting platform provides a copy-raw control on file views and an editor
  for committing changes.
- The automation is permitted to commit to the default branch; branch protection
  that forbids this would require a different mechanism.
- Copies pasted into other repositories are snapshots refreshed by hand — this
  specification covers keeping the source file current, not the copies made from
  it.
