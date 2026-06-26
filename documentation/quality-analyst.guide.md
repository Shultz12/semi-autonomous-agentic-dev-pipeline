# Quality Analyst Guide

## What It Does

Reads accumulated quality data from a completed cycle — **scoped to one agent or skill at a time** — and produces analysis reports about patterns, testing effectiveness, pipeline efficiency, and diagnostic assessments of plan quality, handoff quality, and integration completeness. A separate `synthesis` mode rolls the scoped reports up into a cycle- or milestone-level view.

**Key Points:**
- Analyzes one **(cycle × target)** at a time — the target's own code-review findings, test results, investigations, execution statistics, handoff archives, plans, specs, or refactor proposals (whichever it owns), plus a tight ring of context
- Detects patterns within that target's responsibility surface and classifies findings by promotion threshold (1 = one-off, 2+ = pattern, 3+ = strong pattern)
- Records evidence implicating *other* agents in a `## Cross-Target Observations` section rather than chasing it
- Produces confidence-calibrated recommendations with source attribution
- `synthesis` mode rolls up the scoped reports, correlates their cross-target observations, and — for a milestone — also writes the knowledge-usage report
- Commits each report path-scoped before returning (worktree-side when a cycle anchors the run; main-side for milestone synthesis) and surfaces a `Commit:` field for interrupted-run recovery
- Pure observer of the data it analyzes — reads execution artifacts, never modifies code or pipeline data

## Why Scoped

quality-analyst is an **agent**, and agents cannot dispatch other agents — every run reads files within a single context-bounded read set. Reading *everything* for a real cycle (~250 artifacts, ~470K tokens) overflows a 200K window; "all cycles" or "a whole milestone" is worse. The only provably-bounded unit is **(one cycle × one target)**. So the agent analyzes one target per run, and the **main agent (dispatcher)** composes whole-cycle and whole-milestone coverage by fanning out across (cycle × target) pairs.

## When It's Used

**After a cycle completes:** analyze a specific target (e.g., the developer, or the code-reviewer) in that cycle, or fan out across all of the cycle's targets and finish with a cycle `synthesis` run.

**After a milestone closes:** the main agent runs the milestone fan-out automatically after the last `/accept-feature` of the milestone (per the `accept-feature` skill's post-skill instructions) — scoped runs across every completed cycle's targets, then a milestone `synthesis` run. Also runnable on-demand.

## Modes

| Mode | What It Analyzes | Required Input |
|------|------------------|----------------|
| `agent` | One **agent**'s outputs within one cycle | `Target:` (agent name) + `Cycle Path:` |
| `skill` | One **skill**'s outputs within one cycle | `Target:` (skill name) + `Cycle Path:` |
| `synthesis` | Roll-up of the scoped reports for a cycle or a milestone | `Scope:` (`cycle <path>` or `milestone v<X.Y>`); `Target:` optional |

The `Target:` type is implicit from the mode — `Mode: agent` means `Target:` is an agent name, `Mode: skill` means it's a skill name. There is **no focus filter** and **no cross-cycle mode**: `Target:` *is* the axis you narrow to, and a single cycle is always the read boundary.

`agent` and `skill` modes produce a scoped analysis report. `synthesis` produces a roll-up report (and, for milestone scope, the knowledge-usage report). The agent reads only the small scoped reports during synthesis, so it stays bounded.

## How the Main Agent Fans Out

**For a whole cycle:**
1. Look at the cycle's `execution/`, `plans/`, `specs/` (and `refactor-proposals/` on refactor/primitives cycles) subtrees and map each artifact dir to its owning target (the Read Matrix in `quality-analyst.md` does this mapping). Audits live with their subject — `plan-auditor` under `plans/plan-audit/`, test-plan audits under `plans/test-plans/plan-audit/`, spec/design audits under `specs/` — so don't glob only `execution/`.
2. Run one `Mode: agent` / `Mode: skill` per target.
3. Run one `Mode: synthesis`, `Scope: cycle <path>` to roll them up.

**For a whole milestone:**
1. Read the ROADMAP for the milestone's completed feature cycles.
2. Run the cycle fan-out's scoped runs for each.
3. Run one `Mode: synthesis`, `Scope: milestone v<X.Y>` — it writes both the milestone synthesis report and the knowledge-usage report.

Each scoped run's `Signals-Dropped:` return field names the other targets it implicated, so the main agent knows which additional runs are worth dispatching.

## Understanding the Scoped Report

Reports are written to `.project/pipeline/quality-reports/`. A scoped report is named `<DD-MM-YYYY>-<cycle-slug>-<target>-analysis-run-<K>.md`; `<K>` is a 1-indexed per-day per-(cycle, target) counter that recomputes from `git ls-files` on each dispatch. The report contains only the analysis sections that target is responsible for, plus a `## Cross-Target Observations` section.

- **Code Review Analysis** (code-reviewer) — which issue categories and layers produce the most findings; a low first-attempt PASS rate may indicate plan gaps.
- **Integration Quality** (code-reviewer) — missing exports, stubs, unwired connections.
- **Test Effectiveness** (test-runner) — how well tests catch bugs vs how often tests are wrong, plus BDD coverage.
- **Investigation Analysis** (code-investigator) — how deep investigations go and how often issues escalate.
- **Plan Quality Assessment** (plan-architect / plan-auditor) — plan corrections, plan-caused BLOCKEDs, deviation rates.
- **Handoff Quality Assessment** (state-manager) — what handoffs consistently omitted, with recommendations.
- **Pipeline Efficiency / Developer Run Patterns** (developer) — retry cycles, bottleneck phases, run timelines.
- **Cross-Cutting Patterns / Recommendations** — promoted patterns (2+ occurrences) with source attribution; recommendations ordered by severity then confidence (High/Medium confidence only — LOW findings stay under One-Off Issues).
- **Cross-Target Observations** — evidence implicating *other* targets, recorded for the synthesis run to correlate.

## Understanding the Synthesis Report

A `synthesis` run reads the scoped reports already on disk for its scope and produces:
- **Per-Target Synthesis** — a roll-up per target analyzed.
- **Cross-Target Correlation** — each cross-target observation cross-referenced against the implicated target's own scoped report, with a verdict (corroborated / refuted / unverifiable).
- **Cross-Cutting Patterns** and **Recommendations** promoted across the whole scope.

Cycle synthesis lands at `<DD-MM-YYYY>-<cycle-slug>-synthesis-run-<K>.md`; milestone synthesis at `<DD-MM-YYYY>-<v<X.Y>>-milestone-synthesis-run-<K>.md`.

## Understanding the Knowledge-Usage Report

A **milestone-scope `synthesis` run** additionally writes `.project/pipeline/quality-reports/<DD-MM-YYYY>-<v<X.Y>>-knowledge-usage-report.md` (same-day re-runs overwrite; different-day re-runs add a dated file). Its coverage tables are built from the findings enumerated in the milestone's scoped code-reviewer and developer reports:

- **Health Signal** — the milestone's first-pass code-review PASS rate. A declining rate across milestones flags a pipeline layer paying for itself poorly.
- **By Suggested Knowledge Source** — *Frequency* (findings naming the source) and *Necessity* (phases citing it / phases that produced findings). High frequency means either a missed trigger or a weak skill; high necessity makes a source high-leverage to fix.
- **By Category** — frequency of each `Category` (LOGIC, VALIDATION, INTEGRATION, TYPE, SECURITY, CONVENTION).
- **Category × Severity Cross-Tab** — two-dimensional count table.
- **Findings without knowledge source** — non-CONVENTION findings whose `Suggested knowledge source` is `none` or empty (CONVENTION + `none` is a data defect, surfaced under Data Inconsistencies).

The knowledge-usage report reports **presence and frequency only**. Absence reasoning (sources that should be cited but aren't; conventions that should exist but don't) is `knowledge-curator`'s domain — the report is the data input to that classifier, not classification itself.

## Commit Behavior

Every run commits its own report path-scoped via the `commit-to-git` skill — only the one report file, never unrelated staged work.

| Run | Commit context | Subject |
|---|---|---|
| Scoped (`agent` / `skill`) | Worktree-side (a `Cycle Path:` anchors it) | `quality: <target> scoped report` |
| Synthesis (cycle scope) | Worktree-side | `quality: cycle synthesis report` |
| Synthesis (milestone scope) | Main-side (CWD is the main root) | `quality: milestone synthesis + knowledge-usage report for v<X.Y>` |

The return value carries a `Commit:` field so the dispatcher can detect interrupted runs:

| `Commit:` value | Meaning |
|---|---|
| `<short-hash>` | Written and committed successfully. |
| `skipped` | A re-dispatch produced byte-identical content to HEAD; no new commit. |
| `failed` | The commit step failed; the file is on disk but uncommitted. Do not re-dispatch — investigate manually. |
| `none` | The `OUTPUT_UNWRITABLE` branch fired and no report was written. |

For worktree-anchored runs, the commit lands on the worktree branch and reaches main via `/accept-feature`'s atomic merge.

## Interrupted-Run Recovery

If quality-analyst is killed between the file write and the commit, the report file is on disk but uncommitted. Recovery is implicit: the dispatcher sees the return is missing or carries no `Commit:` field and re-dispatches the same invocation. The re-dispatched run recomputes the per-day per-scope counter `K` from the count of **tracked** same-scope reports plus one — the orphan is untracked, so `K` recomputes to the same value rather than incrementing. The run finds the orphan (Write atomicity guarantees its content is complete), reads it for the return values, and commits it as-is — skipping the analysis. A `Commit: failed` return is a stop signal: the file exists and a re-dispatch would loop; the user resolves it manually.

## Limitations

- Cannot fix code or modify any files it analyzes — reports and recommends only
- Bash access is restricted to an explicit allowlist: `mkdir -p` and `echo` for output registration, `git ls-files` / `wc -l` for the per-scope run counter, and the path-scoped `git add` / `git commit` form supplied by the `commit-to-git` skill
- Analyzes one (cycle × target) per run — whole-cycle and whole-milestone coverage is the dispatcher's fan-out, not a single run
- Pattern detection is based on observed data within the analyzed scope, not statistical analysis
- Quality of analysis depends on quality of data written by other agents — if code-reviewer uses inconsistent categories, aggregation is less meaningful
- Cannot assess code quality directly — analyzes the pipeline's assessment of code quality

## Related Files

- Agent definition: `.claude/agents/quality-analyst/quality-analyst.md`
- Interface contract: `.claude/agents/interface-contracts/quality-analyst.contract.md`
