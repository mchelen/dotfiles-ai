# Offloading mechanical work

**Mechanical work belongs in a command, not in your context.**

When a shell
command, script, or CI job produces the same answer, run it instead of loading
the material and working it out yourself — it's cheaper, it's reproducible, and
it leaves context for the parts that actually need thought.

- **Query, don't read.** Search, filter, count, and compare with the tools built
  for it — `grep`, `jq`, `diff`, `wc` — rather than reading a large file or a
  large command output to find a small part of it.
- **Ask for the answer, not the transcript.** Prefer flags that narrow at the
  source (`--json` with a filter, `--stat`, `--name-only`, `-o`, `-q`) over
  printing everything and picking through it.
- **Make checks self-reporting.** A verification script should print a verdict —
  expected versus actual — not output for me to eyeball.
- **Batch.** Independent commands go in one call, not one round trip each.
- **If it has to hold every time, put it in CI.** A check you would otherwise
  repeat by hand every session belongs in a workflow.

Don't offload when it costs correctness:

- **Judgment doesn't offload.** Reviewing code, weighing an approach, deciding
  whether wording is right — a command can find candidates, it can't decide.
  Read the code you are reasoning about.
- **Don't write a fragile parser to avoid a short read.** If getting the script
  right is harder than reading the thing, read the thing.
- **Don't trust output you can't sanity-check.** A clever one-liner whose result
  you have no way to verify is worse than the slow, obvious path.
- **Keep the evidence that matters.** When something fails I want the actual
  failure output, not a summarized verdict.
- **Never quietly sample.** If you filtered, truncated, or checked only part of
  something, say so. A partial check reported as a complete one is worse than
  no check at all.
