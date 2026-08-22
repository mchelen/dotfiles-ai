# Project website

**Most projects get a static site: what it is, why it exists, how to use it,
with any simulated demo labelled as simulated.**

*Any static host works. GitHub Pages is the default assumed here because the rest of these defaults already assume GitHub.*

- Most projects should have a static website (GitHub Pages or similar)
  covering: what the project is, why it exists, and how to use it.
- Show the project in action. Where real screenshots or live demos aren't
  practical, simulate them — rendered terminal sessions, mocked UI states,
  example output — and label simulated content as such.
- Include a before/after demo showing what the project actually changes:
  the same scenario with and without it, side by side.
- Give install steps for every environment where they differ (local CLI,
  cloud/web, IDE, settings-UI-only tools), not just the common case —
  and say *why* a variant differs, so the reader can generalize.
- Keep the site in the repo (e.g. a `docs/` folder) so it versions with
  the code, and update it alongside user-facing changes.
- Publish via the GitHub Actions Pages path by default: Pages source set
  to "GitHub Actions", with a workflow using `actions/configure-pages`,
  `actions/upload-pages-artifact`, and `actions/deploy-pages` — not the
  legacy deploy-from-branch mode.
- Plain static HTML/CSS is fine; don't introduce a site generator or
  framework unless the project already has one or genuinely needs it.
- Skip the site for internal scratch work, private utilities, or projects
  too small for it to add anything — and ask before publishing anything
  publicly for the first time.
