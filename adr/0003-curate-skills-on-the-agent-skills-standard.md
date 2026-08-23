# 3. Curate skills as a first-class output, on the Agent Skills standard

- **Status:** Accepted. Supersedes, in part,
  [ADR-0001](0001-forkable-repo-for-personal-ai-preferences.md) and
  [ADR-0002](0002-adopt-storytelling-commit-convention.md) — specifically the
  reasoning in each that rejected skills as single-vendor.
- **Date:** 2026-07-26
- **Amended 2026-08-23** — this record flagged four claims as unverified and
  said they "must be checked before anything depends on them." They have now
  been checked; see [Verification, 2026-08-23](#verification-2026-08-23). Two
  are resolved, one corrects an error below, and one could not be checked at
  all. Nothing about the decision changes; what changes is how much of it
  rests on a vendor's assertion.
- **Amended 2026-07-26:** third-party skills are **referenced, never
  vendored**. This closes the copy-vs-pin question the record itself left
  open, before any implementation existed to be superseded.

## Context

### The error being corrected

ADR-0001 rejected "a Claude plugin, skill, or marketplace entry" on the grounds
that it is "single-vendor by construction, and cross-tool reach is the entire
point." ADR-0002 declined the packaging of an adopted convention because "a
Claude skill lives in `~/.claude/skills/`, which is Claude-only and
machine-local."

Both statements are wrong, and were wrong when written.

Claude Code's own documentation says: *"Claude Code skills follow the
[Agent Skills](https://agentskills.io) open standard, which works across
multiple AI tools. Claude Code extends the standard with additional features
like invocation control, subagent execution, and dynamic context injection."*

Skills were Claude-specific when they shipped in October 2025. The
specification was published in December 2025 and governance sits with the
Linux Foundation's Agentic AI Foundation — the same body stewarding
`AGENTS.md`. The claim had an expiry date, was taken from memory and a
secondary source, and was restated three times without being checked. It is
the same failure mode as the earlier assertion that Claude Code reads
`AGENTS.md`, which its documentation also contradicts.

### What the standard actually gives us

Verified first-hand from the Claude Code documentation:

- A skill is a directory containing `SKILL.md`, with optional YAML frontmatter
  — `name`, `description`, `allowed-tools`, `disable-model-invocation`. Only
  `description` is recommended, so Claude knows when to use it.
- Personal skills live at `~/.claude/skills/<skill-name>/SKILL.md`, project
  skills at `.claude/skills/<skill-name>/SKILL.md`, plugin skills under a
  plugin's own `skills/` directory.
- *"Unlike CLAUDE.md content, a skill's body loads only when it's used, so long
  reference material costs almost nothing until you need it."*
- The documented criterion for choosing: create a skill when *"a section of
  CLAUDE.md has grown into a procedure rather than a fact."*

Not verified first-hand, and flagged as such: the contents of `agentskills.io`
(unreachable from this environment), the precise set of tools implementing the
standard, where each non-Claude tool looks for skills on disk, and the plugin
marketplace manifest schema. Those are secondary-source claims and must be
checked before anything depends on them.

### Verification, 2026-08-23

**Resolved — the marketplace manifest schema.** A marketplace is a
`.claude-plugin/marketplace.json` in a git-hosted repo. Required: `name`
(kebab-case, public-facing), `owner` (object, its own `name` required), and
`plugins` (array). Each plugin entry requires `name` and `source`; `description`,
`version`, `author`, and a free-form `metadata` are optional. Users run
`/plugin marketplace add <repo>` then `/plugin install <plugin>@<marketplace>`.
The one-command bootstrap this record assumed does exist, and is small.

**Correction — the frontmatter field list above is wrong.** The Agent Skills
spec defines **six** fields: `name`, `description`, `license`, `compatibility`,
`metadata`, `allowed-tools`. `disable-model-invocation`, listed above as
though it were standard, is a **Claude Code extension**. The consequence is
sharper than "not portable": outside Claude Code — claude.ai uploads, the
Skills API, `package_skill.py` — a non-spec field is a **hard error**, not an
ignored key:

> `Unexpected key(s) in SKILL.md frontmatter: argument-hint. Allowed
> properties are: allowed-tools, compatibility, description, license,
> metadata, name`

So "marked as such rather than silently non-portable" in the Decision below is
too weak. A skill either restricts itself to the six fields or it fails to
package at all. That is a better constraint — it is enforced rather than
remembered — but it means the vendor-neutral core is narrower than this record
assumed.

**Still unverified — which non-Anthropic tools implement the standard, and
where they keep skills on disk.** `agentskills.io` is blocked by this
environment's egress proxy, so the claim of roughly forty supporting tools
remains unchecked from here. What can be confirmed: Anthropic's own
documentation states that "Claude Code skills follow the Agent Skills open
standard, which works across multiple AI tools," and `anthropics/skills`
names Claude Code, claude.ai on paid plans, and the Claude API. **No
non-Anthropic implementer has been confirmed first-hand.**

That matters more than it looks. Decision point 4 — bootstrap where a standard
exists, degrade where it doesn't — assumes other tools to degrade *to*. On the
evidence actually in hand, this may be an Anthropic-governed format that other
tools are said to support, which is a different thing from a multi-vendor
standard. It does not reverse the decision: the format is a plain directory of
markdown, so a copy step serves any tool regardless. But the portability
argument should be treated as unconfirmed until someone can reach
`agentskills.io` or name an implementer.

### The reframing

The commit convention adopted in ADR-0002 arrived **as a skill, from a
marketplace**. That is how this kind of knowledge now circulates, and this
repository had no way to hold one — it could adopt the *prose* of a skill by
hand-copying its rules into a module, which is what ADR-0002 did, but it could
not carry the artifact.

Meanwhile the accumulation goal in ADR-0001 — capturing what is worth keeping —
has a second half that was never addressed: not everything worth keeping is
written here. Deciding which of the ecosystem's thousands of skills are good
enough to keep is itself the valuable act, and the result of that judgment had
nowhere to live.

The owner's constraint on how to close this: build on existing standards, and
accept that they are not equally available everywhere rather than inventing
something uniform.

## Decision

Treat **curated skills as a first-class output** of this repository, alongside
the authored preference modules.

1. **Content standard: Agent Skills.** Skills are stored as
   `<skill-name>/SKILL.md` directories with standard frontmatter. Skills meant
   to travel restrict their frontmatter to the spec's six fields — `name`,
   `description`, `license`, `compatibility`, `metadata`, `allowed-tools` —
   because anything else is a hard packaging error outside Claude Code, not a
   silently ignored key. *(Corrected 2026-08-23; see Verification above.)*

2. **Two sources, both curated.**
   - *Authored here*: modules that are procedures rather than facts become
     skills, by the documented criterion above.
   - *Curated from elsewhere*: third-party skills the owner has evaluated and
     chosen to keep, held as **pinned references** — never copied into this
     repository.

3. **Curation metadata is the deliverable.** For anything sourced elsewhere:
   where it came from, the version pinned, why it was kept, and what to watch
   for upstream. A directory of 2,810 skills already exists; a list of fifteen
   with reasons attached does not.

4. **Bootstrap where a standard exists, degrade where it doesn't.** A Claude
   plugin marketplace manifest gives a one-command install for Claude Code.
   Other tools get a documented copy step into their own skills location. The
   asymmetry is stated in the guide rather than hidden.

5. **The resident block stays for facts.** Always-on behavioral preferences —
   communication, git, code style, testing, feature workflow, secrets, tool
   fallbacks, compute offload — remain modules assembled into the block. They
   shape behavior continuously and are worthless if loaded on demand.

## Considered options

- **Status quo: everything resident.** Simple, and the only option before the
  standard existed. Pays context permanently for material used occasionally,
  and cannot represent curated third-party work at all.
- **Copy third-party skills into the repo (vendoring).** Offline, pinned,
  auditable — and *rejected*. It makes this repository a redistributor of other
  people's work, with the licensing and attribution obligations that carries,
  and copies go stale silently while looking current. The maintenance is real
  and permanent; the benefit is an offline guarantee this project has never
  needed.
- **Reference them by pinned version.** *Adopted.* No redistribution, no
  licence tracking, and upstream fixes are upstream's. The costs are accepted
  knowingly: installation needs network access, and a reference can rot if
  upstream moves or deletes it.
- **Plugin marketplace as the only mechanism.** Rejected: it is the one genuinely
  Claude-specific layer, and making it the sole path reintroduces exactly the
  lock-in this record is correcting for.
- **Invent a portable skill format.** Rejected on the owner's explicit
  instruction to build on existing standards even where coverage is uneven.

## Consequences

- Four modules — `project-website`, `repo-config`, `specification`,
  `architecture` — are candidates to become skills. They are roughly 5,300 of
  the block's ~15,000 characters and are relevant in a minority of sessions.
- Moving them **also shrinks `INSTRUCTIONS-brief.md`**, which currently sits at
  1,430 characters against a 1,500 floor with roughly one module of headroom.
  This turns a looming constraint into slack.
- As skills they can be *longer and better* than a resident module can afford
  to be, since their body costs nothing until invoked.
- New obligations: a second install target and a real risk of sprawl. The value
  is the shortness of the list.
- **A referenced skill cannot be locally patched.** If a third-party skill is
  almost right, the answer is to author one here rather than fork-and-edit
  theirs. That keeps provenance unambiguous: every skill in this repository is
  either wholly ours or wholly someone else's, never a quiet hybrid.
- `install.sh` gains a concern it does not have today. The marker-block
  invariant does not apply to skills — they are whole files in their own
  directories — so this is a genuinely different write path, not an extension
  of the existing one.

## Revisit when

- The Agent Skills specification changes shape, or its governance moves.
- `agentskills.io` becomes reachable, or a non-Anthropic implementation is
  confirmed. Either settles whether the portability premise in this record is
  real or borrowed.
- Referenced skills start disappearing or changing under us often enough
  that pinning by reference stops being reliable, or an offline install
  becomes a requirement — either would reopen the vendoring question.
- Non-Claude tools' skill locations diverge enough that one install step cannot
  serve them, making the "degrade gracefully" promise hollow.
- The curated list grows past the point where each entry's inclusion can still
  be justified in a sentence — at which point it has become a mirror, and the
  curation that justified this record has stopped happening.
