# Feature Specification: Machine sync

**Feature Branch**: n/a — retroactive spec for behavior already shipped in `sync.sh`

**Created**: 2026-07-25

**Status**: Active (describes current intended behavior)

**Input**: Keep every machine's installed preferences current with the user's
fork, automatically and quietly, without the user remembering to do anything.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Yesterday's change is on every machine today (Priority: P1)

A module is edited on one machine and merged. The next time a shell opens on any
other machine, that machine's instruction files already reflect the change.

**Why this priority**: Without this, every machine drifts and the user is back to
remembering which laptop has which preferences.

**Independent Test**: Merge a module change, open a new shell on a second
machine, and confirm its instruction files contain the change.

**Acceptance Scenarios**:

1. **Given** the fork has commits the local clone lacks and the throttle window
   has elapsed, **When** a shell starts, **Then** the clone fast-forwards, the
   installer re-runs, and the run reports the commit range it moved through.
2. **Given** the clone is already current and its installed state matches,
   **When** a shell starts, **Then** nothing is printed and nothing is rewritten.
3. **Given** a sync has already run within the throttle window, **When** another
   shell starts, **Then** no network access is attempted.

---

### User Story 2 - Shell startup is never slowed or noisy (Priority: P1)

The sync runs on every shell start, so it must be invisible: no delay a person
notices, no output when there is nothing to say, and no failure that interrupts
the prompt.

**Why this priority**: Equal in priority to the sync itself — a shell hook that
is slow or chatty gets removed, and then nothing syncs at all.

**Independent Test**: Open shells while offline, while throttled, and while
current, and confirm each produces no output and returns promptly.

**Acceptance Scenarios**:

1. **Given** the machine is offline, **When** an automatic sync runs, **Then** it
   exits quietly and successfully, leaving the installed state untouched.
2. **Given** local history has diverged so a fast-forward is impossible, **When**
   an automatic sync runs, **Then** it exits quietly rather than attempting a
   merge or rewriting history.
3. **Given** the same conditions, **When** the user runs a sync manually,
   **Then** the failure is reported on standard error with a non-zero exit
   status.
4. **Given** a sync attempt fails, **When** the next shell starts within the
   window, **Then** it does not retry — the attempt, not the success, starts the
   throttle window.

---

### User Story 3 - A fresh machine installs on first run (Priority: P2)

A machine that has the clone but has never installed gets configured on its next
shell start, even though the pull finds nothing new to fetch.

**Why this priority**: Without it, cloning on a machine that is already at the
latest commit would leave that machine unconfigured until the next upstream
change.

**Independent Test**: Clone at the current head on a machine with no recorded
installed state, start a shell, and confirm the installer runs.

**Acceptance Scenarios**:

1. **Given** no installed-state record exists, **When** an automatic sync runs,
   **Then** the installer runs even though the pull changed nothing.
2. **Given** the installer has just run, **When** it completes, **Then** the
   commit it installed is recorded so the next run can stay quiet.

---

### Edge Cases

- **Commit hooks unavailable.** When the hook framework is not installed, the
  sync still pulls and installs; hook setup is attempted and its failure ignored.
- **Legacy hook configuration.** A previously configured custom hooks path is
  cleared, so the framework's hooks are the only ones in effect.
- **Re-entrancy.** A pull performed by the sync itself must not cause the
  post-merge hook to run the installer a second time; the sync marks its own
  pull so the hook stands down.
- **Throttle override.** The window is configurable for testing and for users who
  want a different cadence.
- **Unknown option.** The run stops with a distinct non-zero exit status.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST update the local clone from the fork's `main` by
  fast-forward only, never merging or rewriting local history.
- **FR-002**: The system MUST re-run the installer after a successful update.
- **FR-003**: In automatic mode the system MUST attempt at most one sync per
  configurable interval, defaulting to one day.
- **FR-004**: The system MUST start the throttle window when an attempt begins,
  not when it succeeds.
- **FR-005**: In automatic mode the system MUST produce no output when it is
  throttled, offline, unable to fast-forward, or already installed at the current
  commit.
- **FR-006**: The system MUST record the commit whose modules are installed, and
  MUST run the installer when no such record exists.
- **FR-007**: The system MUST report the commit range when it moves the clone
  forward.
- **FR-008**: In manual mode the system MUST report a failed update on standard
  error and exit non-zero.
- **FR-009**: The system MUST install the commit and post-merge hooks when the
  hook framework is available, and MUST continue normally when it is not.
- **FR-010**: The system MUST prevent its own pull from triggering a second,
  redundant install through the post-merge hook.

### Key Entities

- **Clone**: the user's local copy of their fork; its `origin` determines which
  repository every machine follows.
- **Attempt stamp**: the record of when a sync was last attempted, which gates
  the throttle.
- **Installed-commit record**: the commit whose modules are currently written
  into this machine's instruction files.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A merged module change is live on an idle machine by its next shell
  start, with no user action.
- **SC-002**: A shell start with nothing to do produces zero output; when the
  throttle window has not elapsed it also makes no network request at all.
- **SC-003**: At most one sync attempt occurs per interval, no matter how many
  shells are opened.
- **SC-004**: Losing network access never produces an error at the prompt and
  never leaves instruction files half-written.
- **SC-005**: Local commits in the clone are never discarded or rewritten by a
  sync.

## Assumptions

- The clone's `origin` points at a repository the user controls; upstream reaches
  it only when the user syncs the fork.
- The user adds one line to their shell startup file; there is no daemon,
  scheduler, or background process.
- Machines may be offline for long periods, and catching up late is acceptable —
  freshness is best-effort, not guaranteed.
- The user's own commits in the clone are more important than automatic
  updating: the sync stops rather than resolving divergence.
