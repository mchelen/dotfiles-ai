# Cheap git and forge queries

**Ask git and the forge for the smallest thing that answers the question.**

*Tool-agnostic in principle. `minimal_output` is the GitHub MCP server's flag;
elsewhere it's whatever narrows the response at the source.*

History and pull-request APIs return far more than was asked for by default,
and one unbounded response can cost a meaningful share of the context window.
This is the git-shaped half of the compute-offload module.

- **Narrow at the source.** `--stat`, `--name-only`, `--oneline`, `-n`,
  `--no-patch` — reach for these before printing something large and reading
  past most of it. `git log --oneline -10` answers "what happened lately";
  `git log -p` answers the same question at many times the cost.
- **Turn off the pager** (`--no-pager`, or `GIT_PAGER=cat`) so output arrives
  whole instead of a screen at a time.
- **Ask forge tooling for the smallest useful response**: set `minimal_output`
  where the tool supports it, page in small batches, and use server-side
  filters instead of fetching everything and filtering afterwards.
- **Don't pull a large payload to read one field.** When polling something like
  a workflow or check status, request only that status; if a response comes
  back huge anyway, save it and query the field out of the file rather than
  re-fetching.
- **Prefer a scheduled re-check to a tight polling loop** when waiting on CI or
  a deployment.
- **Narrowing is for navigation, not for judgment.** Reviewing a change means
  reading the diff. Use these to find your way to it, not to avoid it.
