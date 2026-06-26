# knowledge-curator Interface Contract

knowledge-curator produces a single proposal file classifying knowledge-artifact findings under `.project/knowledge/**` into a stable two-section structure. It operates in one mode (no `Mode:` parameter accepted). Its output is consumer-agnostic — the proposal names no downstream agent or skill.

## Input

**Provide:**

No mandatory fields. Knowledge-curator discovers all inputs by reading the latest `knowledge-usage-report.md` and enumerating `.project/knowledge/**`.

### Example Invocation

```
Run knowledge-curator.
```

## Output

knowledge-curator writes a proposal file, commits it path-scoped via the `commit-to-git` skill, and returns a structured message. Treat the file as the source of truth; the message carries routing data for the caller and a `Commit:` field that signals interrupted-run recovery.

### Message to Caller

```yaml
status: COMPLETE | BLOCKED
proposal-path: <path to proposal file, or "(not written — output path unwritable)" for OUTPUT_UNWRITABLE>
project-level-items: <count>
user-level-items: <count>
brief-summary: <one-line narrative>
Commit: <short-hash | skipped | failed | none>
```

When the proposal carries a blocked category (`NO_USAGE_REPORT`, `INVALID_USAGE_REPORT`, `NO_ROADMAP`), the message includes:

```yaml
blocked: NO_USAGE_REPORT | INVALID_USAGE_REPORT | NO_ROADMAP
```

(`OUTPUT_UNWRITABLE` returns `status: BLOCKED` instead of `status: COMPLETE` and sets `Commit: none`.)

### `Commit:` Field Semantics

| Value | Meaning |
|---|---|
| `<short-hash>` | The proposal was written and successfully committed path-scoped. |
| `skipped` | A re-dispatch produced byte-identical content to HEAD; no commit was made. The prior commit's content is the source of truth. |
| `failed` | The commit step failed (lock contention, hook rejection, transient error). The proposal file exists on disk and can be committed manually. The dispatcher should investigate; it must not re-dispatch on `failed` (the file is written, so a re-dispatch would loop on the same failure). |
| `none` | Returned only on the `OUTPUT_UNWRITABLE` branch where no proposal file was written this invocation. |

### Output Path

```
.project/pipeline/knowledge-cleanup-proposals/<YYYY-MM-DD>-knowledge-cleanup-proposal-run-<K>.md
```

`<K>` is a per-day 1-indexed run counter computed from `git ls-files '.project/pipeline/knowledge-cleanup-proposals/<YYYY-MM-DD>-knowledge-cleanup-proposal-run-*.md' | wc -l + 1`. The tracked-count rule makes `K` idempotent under interrupted-run recovery — a prior run that wrote the file but died before committing is not tracked, so a re-dispatch computes the same `K` rather than incrementing past the orphan. The wall-clock time of the run is preserved inside the file's `**Date:**` header. The directory is created if it does not exist.

### Recovery

The dispatcher (main agent or user) uses the presence of the `Commit:` field in the return as the recovery signal. If the return is missing entirely or carries no `Commit:` field (process killed, max-turns hit, hook-blocked stop), the dispatcher re-dispatches the same invocation. On re-dispatch:

- The tracked-count `K` recomputes to the same value as the prior attempt (the orphan is untracked, so it is not counted).
- knowledge-curator detects the orphan at the target path (Write-tool atomicity guarantees its content is complete), reads the existing file, and commits it as-is — skipping the LLM analysis. The return reports the resulting hash (or `skipped` if a prior commit happened to land before the re-dispatch).
- If the return reports `Commit: failed`, the dispatcher must NOT re-dispatch — the file is on disk and a re-dispatch would loop on the same failure. The dispatcher surfaces the error to the user for manual resolution.

### Proposal File Structure

The proposal file always contains these two top-level section headings, in this order:

```
## Project-level items
## User-level items
```

When a section has no items, its body is the single line `None.`. Callers parse by section heading; the headings are stable contract.

Each item within a section follows this shape:

```
### <Category> — <short title>

**Target:** <repo-relative path or path glob>
**Trigger:** <evidence sentence>
**Recommendation:** <proposed change>
**Buffer:** <ordinal arithmetic or "n/a">
```

`Post-promotion redundancy` items emit as paired items — one under `## Project-level items` (file removal + `_index.md` row removal), one under `## User-level items` (textual directive to delete a frontmatter line from a user-level skill). The project-level item includes an explicit ordering note.

### Categories

The proposal classifies items into one of these categories. The Section column tells the caller which proposal section the item appears under.

| Category | Section |
|---|---|
| Promote awareness | Project-level |
| Promote from feature-local | Project-level |
| Stale `_index.md` row | Project-level |
| Remove | Project-level |
| Repair `_index` | Project-level |
| Knowledge-map gap (project-level) | Project-level |
| Overlap merge | Project-level |
| Missing cross-reference | Project-level |
| Promote to user-level skill | User-level |
| Knowledge-map gap (user-level) | User-level |
| Post-promotion redundancy | Project-level + User-level (paired) |
| Orphan frontmatter | Project-level |

### Blocked Categories

When knowledge-curator hits a blocked condition, it still writes a proposal (potentially partial) and returns normally with the `blocked:` field set:

| Category | Meaning |
|---|---|
| `NO_USAGE_REPORT` | No `*-knowledge-usage-report.md` file exists in `.project/pipeline/quality-reports/`. Absence-by-citation triggers are disabled; filesystem-only classification proceeds. |
| `INVALID_USAGE_REPORT` | The latest usage report is missing required sections. Same partial-classification behavior. |
| `NO_ROADMAP` | `.project/product/ROADMAP.md` is absent. The feature-count buffer cannot be applied; `Remove`-eligible items are emitted under a `## Deferred — buffer indeterminate` cluster instead. |
| `OUTPUT_UNWRITABLE` | `.project/pipeline/knowledge-cleanup-proposals/` cannot be written. `status: BLOCKED`; no file is created. |

## Guarantees

- The proposal is written to a path under `.project/pipeline/knowledge-cleanup-proposals/` and nowhere else.
- The proposal is committed path-scoped via the `commit-to-git` skill with `Agent: knowledge-curator` and subject `knowledge: cleanup proposal <YYYY-MM-DD>` before the agent returns; the commit names only the one proposal path and never sweeps in unrelated staged work.
- Every return carries a `Commit:` field — a hash on success, `skipped` on byte-identical re-dispatch, `failed` on commit error, or `none` on the `OUTPUT_UNWRITABLE` branch. The absence of `Commit:` in a return is the dispatcher's interrupted-run signal.
- The write+commit workflow is idempotent under re-dispatch: the tracked-count `K` recomputes to the same value when an orphan exists, and the existing-file check skips redundant LLM analysis in favor of committing the prior-attempt's atomically-written file as-is.
- No file outside `.project/pipeline/knowledge-cleanup-proposals/` is modified, deleted, or relocated — knowledge-curator is read-only across every input scope.
- No write occurs under `.claude/` — user-level paths are inspected read-only.
- The proposal contains both `## Project-level items` and `## User-level items` headings, in that order, even when one or both sections have no items (body becomes `None.`).
- Each item names a target path, a trigger evidence sentence, a recommendation, and a buffer disposition.
- No item names a specific downstream agent or skill. Routing is the caller's responsibility; the section heading carries the path-scope signal.
- The "latest" knowledge-usage report is resolved by parsing `DD-MM-YYYY` prefixes chronologically, not lexicographically; same-day ties break by remainder-of-filename lexicographic order.
- The feature-count buffer treats `created-during: pre-pipeline` as ordinal 0 (`features-after-source = total completed feature count`).
- Slugs not found in `Type=feature` ROADMAP entries are resolved against `Type=refactor` and `Type=primitives` entries before being flagged as orphans.
- Files missing `created-during` frontmatter are resolved via a scoped `git log --diff-filter=A --reverse` fallback.
- Same-day legitimate re-runs produce a new proposal file at `run-K+1` (K is a per-day tracked-count counter); no proposal overwrites a prior one.
- Every claim in the proposal is backed by an actual file read, glob result, or bash command output — no fabricated statistics.
- On blocked conditions (`NO_USAGE_REPORT`, `INVALID_USAGE_REPORT`, `NO_ROADMAP`), the proposal is still written with the partial classification and the `blocked:` field set; the caller decides whether to involve the user.
