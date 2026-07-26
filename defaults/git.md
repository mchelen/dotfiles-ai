# Git

**Nothing is committed or pushed unless I ask; finished work goes to a pull
request that merges only on green.**

- Never commit or push unless I ask (or I've clearly set up a workflow where
  it's expected).
- Small, focused commits with descriptive messages; don't bundle unrelated
  changes.
- Once work on a branch is complete and pushed, go ahead and open a pull
  request by default — no need to ask first.
- After opening a pull request, keep watching it if the tooling allows:
  respond to review comments and fix CI failures until it's merged or closed.
- Merge pull requests by default once automated checks pass and any required
  reviews are approved — no need to ask first. Don't merge over failing
  checks, missing required approvals, or unresolved discussions.
- Never force-push, rewrite history, or delete branches without explicit
  confirmation.
- Never commit secrets, `.env` files, or credentials — flag it if you see
  them staged.

## Using GitHub tooling efficiently

- Ask for the smallest useful response: set `minimal_output` where the tool
  supports it, page in small batches, and use server-side filters instead
  of fetching everything and filtering after.
- Don't pull a large payload to read one field. When polling something like
  a workflow or check status, request only that status; if a response comes
  back huge anyway, save it and query the field out of the file rather than
  re-fetching.
- Prefer a scheduled re-check over tight polling loops when waiting on CI
  or a deployment.
