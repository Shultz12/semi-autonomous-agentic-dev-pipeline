# Knowledge Curator Guide

## What It Does

Surveys project-level knowledge artifacts under `.project/knowledge/` and produces a structured proposal that classifies findings into a two-section file — project-level items (changes that land under `.project/`) and user-level items (changes that land under `.claude/`). The proposal is recommendation-only; nothing is executed.

**Key Points:**
- Reads the latest `knowledge-usage-report.md` plus filesystem state to detect dead weight, gaps, redundancy, and promotion candidates
- Inspects user-level skills and routing maps in read-only mode to spot post-promotion redundancy and user-level routing gaps
- Applies a feature-count buffer (≥3 features since the file's source feature) before recommending removal — calendar-time heuristics are too slow for AI-paced development
- Output is consumer-agnostic: never names a downstream agent or skill; the caller routes approved items
- Falls back to git-history queries for files predating the frontmatter convention
- Writes a single proposal file per run with a `run-<K>` suffix so multiple runs the same day coexist; `<K>` is a 1-indexed per-day counter
- Commits the proposal path-scoped before returning and surfaces a `Commit:` field in the return for interrupted-run recovery
- Never modifies, deletes, or relocates any inspected file — proposal-only

## When It's Used

**On-demand by the user.** When you sense knowledge drift, conventions are getting stale, or the last `knowledge-usage-report.md` surfaced uncited sources or recurring no-source findings, invoke knowledge-curator manually.

**On-demand by the main agent.** After `quality-analyst` writes a milestone-mode `knowledge-usage-report.md`, the main agent may dispatch knowledge-curator if the report's aggregate signals indicate dead weight or gaps.

Knowledge-curator is NOT dispatched by `orchestrator`. The orchestrator handles feature, refactor, and primitives work only; knowledge curation runs outside that pipeline.

## Categories

The proposal classifies each finding into one of these categories. Where the item lands tells the caller how to route it.

| Category | Means | Where It Lands |
|---|---|---|
| Promote awareness | A convention exists; the index row's trigger phrasing is too narrow for plans to find it | Project-level |
| Promote from feature-local | A feature-local convention recurs across multiple features and deserves promotion to the top-level `<type>/` | Project-level |
| Stale `_index.md` row | The trigger phrasing in `_index.md` matches no recent plan task; refine the phrasing | Project-level |
| Remove | The file is uncited, no recent plan targets its area, and the buffer has passed; delete the file + its row | Project-level |
| Repair `_index` | A convention file exists but no `_index.md` row points to it; insert the row | Project-level |
| Knowledge-map gap (project-level) | Plan tasks recur in an area but the project-level `_index.md` has no row covering it | Project-level |
| Overlap merge | Two conventions overlap; merge or cross-reference | Project-level |
| Missing cross-reference | One area references a convention; related areas don't | Project-level |
| Promote to user-level skill | A project-level convention applies across unrelated projects; promote to `.claude/skills/developer-skills/<dev-type>/<skill>/` | User-level |
| Knowledge-map gap (user-level) | A user-level routing map needs a row to surface a skill in dispatch | User-level |
| Post-promotion redundancy | A user-level skill has `promoted-from-project-path:` frontmatter AND the project file still exists | Project-level + User-level (paired) |
| Orphan frontmatter | A file's `created-during` slug doesn't match any ROADMAP entry | Project-level |

## Understanding the Proposal

The proposal is written to `.project/pipeline/knowledge-cleanup-proposals/<YYYY-MM-DD>-knowledge-cleanup-proposal-run-<K>.md` and looks like this:

```
# Knowledge Cleanup Proposal

**Reporter:** knowledge-curator
**Date:** 2026-05-19 10:23:45
**Source usage report:** .project/pipeline/quality-reports/12-04-2026-v1.0-knowledge-usage-report.md
**Blocked categories:** None

## Summary

4 stale conventions; 1 promote-to-user-level candidate; 1 post-promotion redundancy.

## Project-level items

### Stale `_index.md` row — backend/persistence/transactions.md

**Target:** .project/knowledge/backend/_index.md
**Trigger:** Row trigger phrasing "transactions" matches no plan task since milestone v0.9; underlying file still valid.
**Recommendation:** Refine trigger phrasing to include "transactional boundary" and "rollback".
**Buffer:** n/a

### Remove — frontend/legacy-modal.md

**Target:** .project/knowledge/frontend/legacy-modal.md
**Trigger:** Not cited in the last 3 features' code-reviews; no recent plan task targets the modal area.
**Recommendation:** Delete the file and its `_index.md` row.
**Buffer:** 5 features after source (ordinal 3 / 8 completed).

## User-level items

### Promote to user-level skill — Hebrew date formatting

**Target:** .claude/skills/developer-skills/frontend/format-hebrew-date/SKILL.md (new)
**Trigger:** Project-level convention `.project/knowledge/frontend/hebrew-date-formatting.md` cited across 4 unrelated feature slugs; applies across projects that handle Hebrew dates.
**Recommendation:** Promote the project-level convention to a user-level skill at `.claude/skills/developer-skills/frontend/format-hebrew-date/SKILL.md`. The promoted skill should carry `promoted-from-project-path: .project/knowledge/frontend/hebrew-date-formatting.md` frontmatter so a future knowledge-curator run can detect post-promotion redundancy.
**Buffer:** n/a
```

## The Feature-Count Buffer

Knowledge-curator uses feature throughput, not calendar time, to decide when a file is "old enough" to remove:

- Each candidate file has a `created-during: <slug>` frontmatter field.
- The buffer requires **≥3 completed features** to have shipped since the source feature before a file becomes `Remove`-eligible.
- Files marked `created-during: pre-pipeline` are treated as ordinal 0 — they pass the buffer as soon as 3 features have shipped overall.
- Files born from refactor/primitives flows resolve their slug against the `Type=refactor` / `Type=primitives` ROADMAP entries; the algorithm maps their reference event onto the feature timeline to derive an effective ordinal.
- Files missing the frontmatter line entirely fall back to a `git log --diff-filter=A --reverse` first-add timestamp.

The threshold of 3 is a heuristic — tunable based on observed false-positive rates. False positives self-heal: `pattern-analyst` (in `convergence-scout` mode) detects re-occurrence of removed conventions and proposes re-extraction.

## Commit Behavior

After writing the proposal, knowledge-curator commits it path-scoped via the `commit-to-git` skill. The commit names only the one proposal file — unrelated staged work in the index is excluded.

| Field | Value |
|---|---|
| Subject | `knowledge: cleanup proposal <YYYY-MM-DD>` (today's date, same as in the filename) |
| Trailer | `Agent: knowledge-curator` |
| Path scope | the proposal path only |

The return message carries a `Commit:` field so the dispatcher can detect interrupted runs:

| `Commit:` value | Meaning |
|---|---|
| `<short-hash>` | The proposal was written and committed successfully. |
| `skipped` | A re-dispatch produced byte-identical content to HEAD; no new commit was made. |
| `failed` | The commit step failed; the file is on disk but uncommitted. Do not re-dispatch — investigate manually. |
| `none` | The `OUTPUT_UNWRITABLE` branch fired and no proposal was written this invocation. |

## Interrupted-Run Recovery

If knowledge-curator is killed (max-turns hit, hook-blocked stop, transient error) between the file write and the commit, the proposal file is on disk but uncommitted. The recovery mechanism is implicit:

- The dispatcher (main agent or user) sees the return is missing or carries no `Commit:` field, and re-dispatches the same invocation.
- The re-dispatched agent computes the per-day run counter `K` from the count of **tracked** same-day proposals plus one. The orphan from the prior crashed attempt is untracked, so `K` recomputes to the same value rather than incrementing past the orphan.
- The re-dispatched agent finds the orphan at the target path. Because the Write tool is atomic, the file's content is complete — the prior attempt wrote everything and died only at the commit step. The agent reads the file for the return values and commits it as-is, skipping the LLM analysis.

A `Commit: failed` return is a stop signal: the file exists and a re-dispatch would loop on the same failure. The user resolves it manually.

## What Happens With Approved Items

Knowledge-curator does NOT execute any items. Approval and routing happen elsewhere:

- **Project-level items** are typically routed to `state-manager` (`refactor-curation` mode), which handles project-level convention edits and removals under approved-knowledge-cleanup-proposal precondition.
- **User-level items** include a mix:
  - `Promote to user-level skill` items are typically routed to `agent-architect` (`promote-skill` mode).
  - `Knowledge-map gap (user-level)` items are typically routed to `agent-architect` (`update-knowledge-map` mode).
  - The textual directive half of `Post-promotion redundancy` items is typically applied directly by the user or main agent as a one-line frontmatter edit.

Knowledge-curator does not encode any of this routing — section headings carry the path-scope signal, and the caller chooses the executor.

## Limitations

- Cannot fix, delete, or relocate anything — proposal-only
- Bash access is restricted to an explicit allowlist: `mkdir -p` and `echo` for output registration, `git ls-files` / `wc -l` for the run counter, `git log --diff-filter=A --reverse` for the missing-frontmatter fallback, and the path-scoped `git add` / `git commit` form supplied by the `commit-to-git` skill
- Pattern detection depends on the quality of the latest `knowledge-usage-report.md`; if no report exists, absence-by-citation triggers are disabled and only filesystem signals are used
- The feature-count buffer requires `.project/product/ROADMAP.md` — without it, `Remove`-eligible items are deferred rather than classified
- Cannot detect a convention that is genuinely needed but never written — only what exists, what is cited, and what is structurally inconsistent
- Cannot reason about whether a proposed promotion is a good idea at the cross-project level — proposes promotions based on observed cross-feature applicability; the caller exercises judgment

## Related Files

- Agent definition: `.claude/agents/knowledge-curator/knowledge-curator.md`
- Interface contract: `.claude/agents/interface-contracts/knowledge-curator.contract.md`
- Companion analysis agent: `.claude/agents/quality-analyst/quality-analyst.md` (produces the milestone-mode `knowledge-usage-report.md` that feeds knowledge-curator)
- Related agent (downstream execution): `.claude/agents/state-manager/state-manager.md` (`refactor-curation` mode handles approved project-level cleanup items)
- Related skill (downstream execution): `.claude/skills/agent-architect/` (`promote-skill` and `update-knowledge-map` modes handle approved user-level items)
