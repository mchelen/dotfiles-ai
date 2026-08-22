# Feature Specification: User-level install

**Feature Branch**: n/a — retroactive spec for behavior already shipped in `install.sh`

**Created**: 2026-07-25

**Status**: Active (describes current intended behavior)

**Input**: Assemble the preference modules into one block and place it in the
user-level instruction file of every AI coding tool on a machine, without
disturbing anything the user wrote in those files.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Configure a new machine in one command (Priority: P1)

Someone sets up a laptop, clones their fork, and runs the installer. Every AI
coding tool already on that machine starts following their preferences, without
them opening a single config file.

**Why this priority**: This is the product. Everything else is upkeep of the
state this creates.

**Independent Test**: On a machine with at least one supported tool's config
directory present, run the installer and confirm that tool's instruction file
now contains the assembled block.

**Acceptance Scenarios**:

1. **Given** `~/.claude/` exists and `~/.claude/CLAUDE.md` does not, **When** the
   installer runs, **Then** the file is created containing the block delimited by
   the `BEGIN`/`END` markers, and the run reports it as installed.
2. **Given** `~/.qwen/` does not exist, **When** the installer runs, **Then** no
   file is created under it and the run reports that target as skipped, naming
   the missing directory.
3. **Given** several tools' config directories exist, **When** the installer runs
   once, **Then** every one of them receives the same block.

---

### User Story 2 - Change a preference without losing personal notes (Priority: P2)

A module is edited. The installer is re-run on a machine whose instruction files
also contain notes the user wrote by hand. The preferences update; the notes are
untouched.

**Why this priority**: Preferences change constantly, so this path runs far more
often than a first install. A tool that eats hand-written content stops being
run at all.

**Independent Test**: Add text above and below an existing managed block, re-run
the installer, and diff — only the block's contents may differ.

**Acceptance Scenarios**:

1. **Given** a target file containing a managed block plus user text before and
   after it, **When** the installer runs, **Then** the user text is byte-identical
   afterwards and only the block content changes.
2. **Given** the same file, **When** the installer runs, **Then** the previous
   version is saved alongside it with a `.bak` suffix and the run reports the
   target as updated.
3. **Given** the installer has run any number of times, **When** the target file
   is inspected, **Then** it contains exactly one `BEGIN` marker and one `END`
   marker.
4. **Given** a target file that exists with user content but no managed block,
   **When** the installer runs, **Then** the block is appended after a blank line
   and the existing content is preserved.
5. **Given** a managed block whose `BEGIN` line carries trailing whitespace,
   **When** the installer runs, **Then** the old block is still replaced: the
   file ends with exactly one block and none of the previous block's content
   survives.
6. **Given** a file containing a `BEGIN` marker with no `END`, **When** the
   installer runs, **Then** it exits non-zero with a message naming the file,
   and every line of that file is unchanged.

---

### User Story 3 - Supply the text to a tool that has no file (Priority: P3)

Some tools take instructions only through a settings field or a repo file. The
user needs the assembled text as text, without anything being written to disk.

**Why this priority**: It unlocks every tool the file-based path cannot reach —
settings-UI tools and cloud agents — and it is what `INSTRUCTIONS.md` is
generated from.

**Independent Test**: Run the installer in print mode and confirm the block is
written to standard output and no target file is created or modified.

**Acceptance Scenarios**:

1. **Given** any machine state, **When** the installer runs in print mode,
   **Then** the assembled block is written to standard output, nothing on disk is
   modified, and the command exits successfully.

---

### Edge Cases

- **No modules present.** The run fails with a message naming the empty
  directory rather than writing an empty block over existing files.
- **Unknown option.** The run stops with a distinct non-zero exit status and
  does not partially install.
- **A `BEGIN` marker with no matching `END`.** *Resolved: the run aborts and
  the file is left untouched.* Previously it dropped everything from the marker
  to end-of-file **and exited zero**, so the loss was silent and the `.bak` copy
  was the only recovery. Refusing is right here: the tool cannot tell an
  interrupted write from a deliberate edit, and guessing wrong destroys content
  it did not author.
- **A marker line altered by hand** (trailing or leading whitespace).
  *Resolved: markers are compared with surrounding whitespace trimmed, and
  detection and removal use that one comparison.* Previously detection matched
  the line loosely while removal required an exact match, so a `BEGIN` line
  with a trailing space was found but not removed — the run reported success,
  the stale block survived, and a second block was appended, deviating from
  FR-006 and SC-002.
- **Two comparisons that can drift apart.** The defect above existed because
  "is there a block?" and "which lines are the block?" were answered by
  different code. They are now one function, so the two answers cannot
  disagree again.
- **Target directory exists but the file is read-only or not writable.** Not
  currently distinguished from other failures. [NEEDS CLARIFICATION: should one
  unwritable target abort the whole run or be reported and skipped?]

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST assemble every `.md` file in `defaults/` into a
  single block, in filename order, with no module omitted.
- **FR-002**: The system MUST delimit that block with the `BEGIN` and `END`
  HTML-comment markers, on their own lines.
- **FR-003**: The system MUST write to a tool's instruction file only when that
  tool's configuration directory already exists, unless the operator requests
  every target explicitly.
- **FR-004**: The system MUST offer a mode that writes every known target
  regardless of detection.
- **FR-005**: The system MUST offer a mode that prints the assembled block to
  standard output and modifies nothing.
- **FR-005a**: The system MUST offer a second print mode producing a condensed
  form — one line per module, drawn from that module's thesis sentence — for
  destinations that cap instruction length. It MUST fail, naming the file,
  when a module has no thesis sentence, rather than silently omitting it.
  The condensed form carries no `BEGIN`/`END` markers: its destinations are
  replaced wholesale, so markers would spend a meaningful share of a hard
  character budget on nothing.
- **FR-006**: On re-run, the system MUST replace the existing managed block in
  place rather than appending a second one.
- **FR-007**: The system MUST preserve all file content outside the markers,
  unchanged.
- **FR-008**: The system MUST save a backup copy before rewriting a file that
  already contains a managed block.
- **FR-009**: The system MUST report, per target, whether it was installed,
  updated, or skipped, and why it was skipped.
- **FR-010**: The system MUST fail without writing when no modules are found,
  and MUST exit with a distinct status for an unrecognized option.
- **FR-011**: The set of target files MUST be a single declared list, so
  supporting a new tool is one entry.
- **FR-012**: Marker matching MUST ignore leading and trailing whitespace, and
  the same comparison MUST decide both whether a block is present and which
  lines constitute it. A single implementation, not two that agree by
  convention.
- **FR-013**: A `BEGIN` marker with no matching `END` MUST abort with a
  distinct non-zero status, naming the file, and MUST leave that file
  unmodified. Destroying unauthored content is never the fallback.

### Key Entities

- **Module**: one markdown file in `defaults/`, self-contained and
  tool-agnostic, written as direct instructions to an assistant. Each opens
  with a **thesis sentence** — one bold paragraph under the heading — that
  states the preference in a single line and is the source for the condensed
  form.
- **Managed block**: the assembled modules plus their delimiting markers; the
  unit that is inserted, replaced, and removed as a whole.
- **Target**: the absolute path of one tool's user-level instruction file,
  paired with the directory whose existence signals that the tool is in use.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new machine goes from a fresh clone to fully configured with one
  command and zero manual file edits.
- **SC-002**: After any number of consecutive runs, every target file contains
  exactly one managed block.
- **SC-003**: Content outside the markers is byte-identical before and after a
  run, in every target.
- **SC-004**: No file is created for a tool that is not installed on the machine.
- **SC-005**: Adding a module changes no file other than the new module and the
  generated copies of the block.
- **SC-007**: Every acceptance scenario above is executable. `./test.sh` runs
  them against a throwaway `HOME` and fails the build if any regresses.
- **SC-006**: The condensed form fits the smallest instruction field this
  project documents. It is currently 1,435 characters against a 1,500
  character floor, and the thirteenth module already required tightening two
  thesis sentences to stay under it — at
  which point the floor is missed and the guide must say so rather than
  quietly overflow.

## Assumptions

- Instruction files are plain markdown that tools read whole; no tool requires
  the block to be in a particular position within the file.
- The user is willing to have a backup file written next to each target.
- Filename order is an acceptable module order; no module depends on appearing
  before or after another.
- One machine, one user account: targets are resolved relative to the running
  user's home directory.
