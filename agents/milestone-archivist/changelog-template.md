# Changelog Template

Path written by milestone-archivist: `.project/product/releases/v<X.Y>/CHANGELOG.md`

Produced once per milestone, on the acceptance of the milestone's last feature. Sourced exclusively from the supplied cycle-summary files; never re-derived from raw phase summaries.

## Template

```markdown
# v<X.Y> — <Milestone Description>

Completed: <YYYY-MM-DD>

## Features

### <Feature Name>
- <User-facing summary sourced from the feature summary's "What Was Built" section, condensed to 1–3 bullets>
- <Key capabilities added, one bullet each>

### <Feature Name>
- ...

## Breaking Changes

<Schema migrations, API changes, removed endpoints — sourced from each feature summary's "Schema Changes" and "Key Architectural Decisions" sections. Group by feature when more than one feature contributes. Write "None" if no breaking changes across the milestone.>

## Known Limitations

<Accepted test failures and documented constraints — sourced from each feature summary's "Testing Summary" section (the "Accepted failures" line). Write "None" if no limitations.>
```

## Authoring rules

- **Order features alphabetically by name** so the CHANGELOG is stable across re-renders if the same milestone is regenerated (e.g., after a fix to a feature summary that pre-dated archival).
- **Condense, do not paraphrase wholesale.** The feature summary's "What Was Built" is the user-facing source of truth; preserve its facts and its phrasing where possible.
- **Aggregate Breaking Changes across all features**, but keep them grouped by feature (`### <Feature Name>` sub-headings under Breaking Changes if more than one feature contributes). Single-feature milestones may use a flat bullet list.
- **Aggregate Known Limitations the same way**, but use a flat bullet list — accepted failures are usually short.
- **Never invent content.** If a section has nothing to report (no breaking changes, no known limitations), write "None" rather than padding.
- **Never reference internal artifacts** (phase summaries, manifest, handoffs) — the CHANGELOG is the user-facing record of the version.
