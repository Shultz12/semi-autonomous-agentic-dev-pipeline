# quality-analyst Interface Contract

quality-analyst operates in three modes. The only provably-bounded unit of analysis is **(one cycle × one target)** — one agent's or one skill's outputs within a single cycle. Reading *everything* for a cycle, or for a whole milestone, overflows a context window, so there are no `cycle`/`cross-cycle`/`milestone` read-everything modes.

- **`agent` mode** (scoped) — quality analysis of one **agent** Target within one cycle.
- **`skill` mode** (scoped) — quality analysis of one **skill** Target within one cycle.
- **`synthesis` mode** — rolls up the already-written scoped reports for a cycle or a milestone (and, for milestone scope, also emits the knowledge-usage report).

`Target:` type is **implicit from `Mode:`**: `Mode: agent` ⇒ `Target:` is an agent name; `Mode: skill` ⇒ `Target:` is a skill name. There is **no** `Target-Type:` field and **no** `Focus:` parameter — `Target:` is the focus axis.

The **dispatcher** (the main agent) owns the fan-out across (cycle × target) pairs; quality-analyst never fans out (it is an agent, and agents cannot dispatch other agents). The fan-out procedure is documented below so the dispatcher can drive it, explain it, and warn the user when a required input is missing.

## Input — `agent` mode

Analyze one agent's outputs within a single cycle.

**Required (both):**
```
Mode: agent
Target: <agent name>            # must match a known agent in agents/interface-contracts/_index.md
Cycle Path: .project/cycles/<cycle>/
```

quality-analyst full-reads the agent's own outputs in that cycle (the `primary` set of its Read-Matrix row) plus a tight context ring (Grep frontmatter; full-read only on a concrete signal). It never reads the row's `excluded` set.

### Example Invocation — `agent` mode

```
Mode: agent
Target: developer
Cycle Path: .project/cycles/15-03-2026-notification-system/
```

## Input — `skill` mode

Same shape as `agent` mode; `Target:` names a skill.

**Required (both):**
```
Mode: skill
Target: <skill name>            # must match .claude/skills/<name>/SKILL.md
Cycle Path: .project/cycles/<cycle>/
```

### Example Invocation — `skill` mode

```
Mode: skill
Target: orchestrator
Cycle Path: .project/cycles/15-03-2026-notification-system/
```

## Input — `synthesis` mode

Roll up the scoped reports already on disk for a scope.

**Required:**
```
Mode: synthesis
Scope: cycle .project/cycles/<cycle>/   |   milestone v<X.Y>
```

**Optional:**
```
Target: <agent or skill name>           # restrict the roll-up to one target across the scope
```

`milestone v<X.Y>` must match `^v\d+\.\d+$` and resolve (via the ROADMAP) to a milestone with completed cycles. quality-analyst reads the small scoped reports matching the scope; it may do a single targeted evidence read but never re-reads raw artifacts in full. For milestone scope it additionally writes the knowledge-usage report.

### Example Invocations — `synthesis` mode

```
Mode: synthesis
Scope: cycle .project/cycles/15-03-2026-notification-system/
```

```
Mode: synthesis
Scope: milestone v1.0
```

## The Fan-Out (dispatcher-driven)

quality-analyst analyzes one (cycle × target) per run. The dispatcher composes whole-cycle and whole-milestone analysis from those runs.

**To analyze a whole cycle C:**
1. Enumerate the targets that produced artifacts in C — Glob C's `execution/`, `plans/`, and `specs/` (and `refactor-proposals/` on refactor & primitives cycles) subtrees, and map each artifact dir to its owning target via the Read Matrix in `quality-analyst.md`. An audit lives with its subject, so `plan-auditor` reports sit under `plans/plan-audit/`, test-plan audits under `plans/test-plans/plan-audit/`, design/spec audits under `specs/`, and the pattern audit under `refactor-proposals/`; an `execution/`-only glob would miss those targets.
2. Dispatch one `Mode: agent` / `Mode: skill` run per target → N scoped reports.
3. Dispatch one `Mode: synthesis`, `Scope: cycle <C>` run → one cycle synthesis report.

**To analyze a whole milestone v<X.Y>:**
1. Resolve the milestone's completed cycles from the ROADMAP (its `Type: feature` entries with `Status: completed`).
2. For each cycle, run the cycle fan-out's scoped runs (step 2 above) → M×N scoped reports.
3. Dispatch one `Mode: synthesis`, `Scope: milestone v<X.Y>` run → one milestone synthesis report **and** the knowledge-usage (coverage) report.
4. `milestone-archivist` (and, on demand, `knowledge-curator`) run as they do today.

The dispatcher owns this loop; quality-analyst's `Signals-Dropped:` return field tells the dispatcher which additional targets a scoped run implicated (so it can offer to chain them).

## Output

quality-analyst writes a report, commits it path-scoped via the `commit-to-git` skill (worktree-side when a `Cycle Path:` anchors the run, main-side for milestone-scope synthesis), and returns a structured message. Treat the report as the source of truth; the message carries routing data and a `Commit:` field that signals interrupted-run recovery.

### Message to Caller — scoped (`agent` / `skill`)

```
Mode: [agent | skill]
Target: [agent or skill name]
Cycle: [cycle-slug]
Report: [path to report file]
Signals-Dropped: [implicated-target:count, ... | none]
Commit: [short-hash | skipped | failed | none]
```

### Message to Caller — `synthesis`

```
Mode: synthesis
Scope: [cycle <cycle-slug> | milestone v<X.Y>]
Report: [path to synthesis report]
Knowledge-Usage Report: [path | n/a (cycle scope)]
Commit: [short-hash | skipped | failed | none]
```

### `Commit:` Field Semantics

| Value | Meaning |
|---|---|
| `<short-hash>` | The report was written and successfully committed path-scoped (worktree-side when a `Cycle Path:` anchored the run; main-side for milestone-scope synthesis). |
| `skipped` | A re-dispatch produced byte-identical content to HEAD; no new commit was made. The prior commit's content is the source of truth. |
| `failed` | The commit step failed (lock contention, hook rejection, transient error). The report file exists on disk and can be committed manually. The dispatcher must NOT re-dispatch on `failed` (the file is written; a re-dispatch would loop on the same failure). |
| `none` | Returned only on the `OUTPUT_UNWRITABLE` branch where no report file was written this invocation. |

### Blocked Conditions

If quality-analyst hits a blocked condition, it still returns the standard message for the mode (with `Report:` pointing at a *blocked-analysis report* that carries a `blocked:` frontmatter field). The categories are:

| Category | Meaning |
|---|---|
| `INVALID_INPUT` | Scoped: `Cycle Path:` missing/absent/empty, or `Target:` missing or not a known agent/skill. Synthesis: `Scope:` missing or unresolvable (neither a real `cycle <path>` nor a `milestone v<X.Y>` with completed cycles). |
| `NO_DATA` | Scope is valid but contains no analyzable artifacts: scoped — the Target produced none of its `primary` outputs in this cycle; synthesis — no scoped reports match the scope. |
| `OUTPUT_UNWRITABLE` | `.project/pipeline/quality-reports/` cannot be created or written. `Report:` reads `(not written — output path unwritable)` instead of a path. |

## Output Paths

| Output | Path |
|---|---|
| Scoped report (`agent` / `skill`) | `.project/pipeline/quality-reports/<DD-MM-YYYY>-<cycle-slug>-<target>-analysis-run-<K>.md` |
| Synthesis report (cycle scope) | `.project/pipeline/quality-reports/<DD-MM-YYYY>-<cycle-slug>-synthesis-run-<K>.md` |
| Synthesis report (milestone scope) | `.project/pipeline/quality-reports/<DD-MM-YYYY>-<v<X.Y>>-milestone-synthesis-run-<K>.md` |
| Knowledge-usage (coverage) report — milestone synthesis only | `.project/pipeline/quality-reports/<DD-MM-YYYY>-<v<X.Y>>-knowledge-usage-report.md` |

`<K>` is a 1-indexed per-scope per-day run counter computed from `git ls-files '<scope-prefix>-run-*.md' | wc -l + 1`. The tracked-count rule makes `K` idempotent under interrupted-run recovery — a prior run that wrote the file but died before committing is not tracked, so a re-dispatch computes the same `K`. The `<target>` segment is the literal target name. The knowledge-usage report uses a deterministic per-day filename (no `run-<K>`); same-day re-runs overwrite, different-day re-runs add a dated file. Downstream consumers (e.g., `knowledge-curator`) resolve "latest" by the `DD-MM-YYYY` segment, not by lexicographic sort.

### Recovery

The dispatcher uses the presence of the `Commit:` field in the return as the recovery signal. If the return is missing entirely or carries no `Commit:` field (process killed, max-turns hit, hook-blocked stop), the dispatcher re-dispatches the same invocation. On re-dispatch the tracked-count `K` recomputes to the same value (the orphan is untracked), quality-analyst detects the orphan at the target path (Write-tool atomicity guarantees its content is complete), reads the existing file, and commits it as-is — skipping the LLM analysis. If the return reports `Commit: failed`, the dispatcher must NOT re-dispatch — the file is on disk and a re-dispatch would loop on the same failure; the dispatcher surfaces the error for manual resolution.

## Cross-Target Observations and Synthesis Correlation

There is **no signal-queue file**. A scoped run that, while reading its Target, notices evidence implicating a *different* agent or the plan records it in a `## Cross-Target Observations` section of its own report — it does not deep-dive the other target and does not write into any other file. The `synthesis` run collates every such observation across the in-scope scoped reports and cross-references each against the implicated target's own scoped report (and, if needed, a single targeted evidence read) to corroborate or refute it before promoting it.

## Guarantees

- Every run is bounded to one (cycle × target) — scoped modes never read "everything" for a cycle, and `synthesis` reads only the small distilled scoped reports plus optional single-file evidence reads.
- A scoped run never deep-dives a non-Target agent; it records cross-target observations and lets `synthesis` correlate them.
- `synthesis` correlates each cross-target observation against the implicated target's own scoped report before promoting it; a milestone-scope `synthesis` run additionally emits the knowledge-usage report at the unchanged path/name so `knowledge-curator` finds it.
- Every claim in any report is backed by an actual file read — no fabricated statistics.
- Source files (code-reviews, test-results, investigations, summaries, plans, specs, developer reports) are never modified — the analysis is read-only.
- Missing data categories appear explicitly in Data Completeness; nothing is silently omitted; the safety valve sub-scopes by phase range and records truncation rather than dropping data.
- Sections with zero findings are included (zero is meaningful data); a scoped report includes only the analysis sections in its Target's responsibility surface.
- The `.project/pipeline/quality-reports/` directory is created if it does not exist.
- `Target:` type is implicit from `Mode:` (agent ⇒ agent name, skill ⇒ skill name); there is no `Target-Type:` and no `Focus:` parameter, and no `cross-cycle` scope.
- Scoped pattern classification uses promotion thresholds: 1 occurrence = one-off, 2 = pattern, 3+ = strong pattern; `synthesis` promotes patterns across the scope. The knowledge-usage report does not classify or recommend — it reports presence and frequency only; absence and dead-weight reasoning are `knowledge-curator`'s domain.
- Every recommendation carries two independent labels — confidence (High/Medium) and severity (High/Medium/Low). LOW-confidence findings are held back from Recommendations and surface only under One-Off Issues.
- Every cross-cutting pattern includes source attribution (plan/handoff/code-review/test/integration/spec).
- Before writing, a scoped run runs a self-criticism pass (disconfirmation, confidence, attribution, severity) so the published classifications reflect the post-criticism state.
- On blocked conditions, quality-analyst writes a blocked-analysis report and returns normally instead of asking the user directly.
- Every mode commits its own report path-scoped via the `commit-to-git` skill with `Agent: quality-analyst`. The commit is worktree-side when a `Cycle Path:` anchors the run (scoped modes and cycle-scope synthesis run inside `.worktrees/<cycle>/`) and main-side for milestone-scope synthesis (CWD is the main root); the skill's CWD-based context resolution selects the right variant. The path-scoped form never sweeps unrelated staged work into the report's commit.
- Every return carries a `Commit:` field — a hash on success, `skipped` on byte-identical re-dispatch, `failed` on commit error, or `none` on the `OUTPUT_UNWRITABLE` branch. The absence of `Commit:` in a return is the dispatcher's interrupted-run signal.
- The write+commit workflow is idempotent under re-dispatch: the tracked-count `K` recomputes to the same value when an orphan exists, and the existing-file check commits the prior-attempt's atomically-written file as-is.
- The agent never commits anything other than the report it just wrote — the path-scoped commit names only the one file under `.project/pipeline/quality-reports/` and never sweeps in source code, test code, or other agents' artifacts.
- The agent never writes `.project/product/ROADMAP.md` or any file under `.project/product/cycles-in-progress/` from any mode; on a merge conflict touching those paths in a worktree-anchored run, main's version is taken unconditionally.
