# Orchestration Summary Format

Per-phase observability report. Written at the start of Step I, before the state-manager is spawned, so that state-manager curates the phase artifacts knowing the orchestration-summary is on disk. The orchestrator commits the summary path-scoped via the `commit-to-git` skill immediately after writing it, before dispatching state-manager. One file per phase.

## Output Path

- Phase summaries: `[cycle-path]/execution/orchestration-summaries/phase-[N]-orchestration-summary.md`

## Resume Marker

When the orchestrator writes a phase's summary while the state-file `Resumed:` flag is `true` (see `essentials/state-format.md`), place this marker block between the frontmatter's closing `---` and the `# Phase [N] Orchestration Summary` heading:

```markdown
> ⚠ Generated on resume. Phase-tracking data prior to the resume point was lost when the prior orchestrator session ended; entries below cover only events the resumed session observed.
```

The flag is `true` only when the current phase began in a different orchestrator session than the one writing the summary. A resume that crosses a phase boundary self-clears at the next Step A's per-phase reset, so the next phase's summary is unmarked. When `Resumed: false`, omit the marker entirely.

## Template

```markdown
---
phase: [N]
cycle: [cycle-slug]
outcome: [completed | escalated | interrupted]
dispatches-count: [integer — rows in "Agent Dispatches"]
boundary-violations: [integer — count of "VIOLATION" rows in "Files Read"]
bash-violations: [integer — count of "VIOLATION" rows in "Bash Commands"]
files-read-count: [integer — rows in "Files Read"]
---

# Phase [N] Orchestration Summary: [phase-name]

## Overview

- **Cycle:** [name]
- **Phase:** [N] of [total]
- **Developer Type:** [from phase]
- **Outcome:** [completed | escalated | interrupted]

## Files Read

Every file the orchestrator read during this phase. Mark violations against orchestrator-boundaries.md.

| # | File | Reason | Allowed |
|---|------|--------|---------|
| 1 | [path] | [why it was read] | [Yes / VIOLATION] |

**Allowed reads per phase:** plan file (current phase section), reference files (recovery-paths, diagnostic-routing, investigation-routing when triggered), state file (updates). Essentials are loaded at startup, not per-phase.

**Violations:** agent report files, source code, test files, handoff contents, investigation file contents, manifest contents, phase summary contents.

## Bash Commands

Every Bash command the orchestrator executed during this phase.

| # | Command | Reason | Allowed |
|---|---------|--------|---------|
| 1 | [command] | [why it was run] | [Yes / VIOLATION] |

**Allowed commands per phase:** `git rev-parse HEAD` (phase start commit), and `git add` / `git commit` (path-scoped, via `commit-to-git`, for the orchestration-summary at the end of Step I). All other commands listed in `orchestrator-boundaries.md` are startup- or completion-only and should not appear in per-phase summaries. The commit of the orchestration-summary itself is not listed in this table — it occurs after the summary is written, so it cannot appear in the row inventory the summary captures.

## Agent Dispatches

Every agent spawned during this phase, in chronological order.

| # | Agent | Trigger/Mode | Status Returned | Report Path |
|---|-------|-------------|-----------------|-------------|
| 1 | developer | Phase implementation | [COMPLETED/PARTIAL/BLOCKED] | [path] |
| 2 | code-reviewer | PHASE_REVIEW (or ABSTRACT_MIGRATION_REVIEW) | [PASS/FAIL] | [path] |
| ... | ... | ... | ... | ... |

## Incidents

Anything abnormal that happened. If none: "No incidents."

Each incident:

### [Short title]

- **Type:** [re-spawn | escalation | recovery-path | missing-file | counter-pressure | boundary-violation | missing-commit]
- **Agent:** [agent name, or "orchestrator" for self-violations]
- **Detail:** [what happened]
- **Resolution:** [how it was resolved, or "escalated to user"]

Incident types:
- **re-spawn** — agent re-invoked due to missing return fields or failed output
- **escalation** — counter limit reached or unresolvable issue, escalated to user
- **recovery-path** — PARTIAL continuation, BLOCKED handler, or NOTIFY Deviations triggered
- **missing-file** — agent claimed to write a file that doesn't exist at the expected path
- **counter-pressure** — any counter exceeded 1 (retries needed)
- **boundary-violation** — orchestrator read a file or ran a command outside its allowed set
- **missing-commit** — committing subagent returned without a `Commit:` field, triggering re-dispatch per the interrupted-commit recovery rule in `orchestrator-boundaries.md`

## Phase Counters

| Counter | Final Value | Limit | Notes |
|---------|-------------|-------|-------|
| Implementation Attempts | [N] | 3 | [blank if 1, otherwise brief note] |
| Test Writing Attempts | [N] | 3 | |
| CODE_BUG Fixes | [N] | 2 | |
| TEST_BUG Fixes | [N] | 2 | |
| Handoff Rebuilds | [N] | 2 | |
| Partial Continuations | [N] | 3 | |

## Decisions

User decisions made during this phase. If none: "No decisions required."

| # | Context | Decision | Outcome |
|---|---------|----------|---------|
| 1 | [what triggered the decision] | [what the user chose] | [result of that choice] |
```

## Frontmatter Fields

The YAML frontmatter is the first thing in the file (byte 0), ahead of the optional resume marker and the `# Phase [N]` heading. Each field mirrors data already present in the body:

- `phase` — the phase number (matches the H1 and the Overview `Phase` line).
- `cycle` — the cycle slug.
- `outcome` — mirrors the Overview `Outcome` value; uses that same enum (`completed | escalated | interrupted`) and no other values.
- `dispatches-count` — the number of rows in the **Agent Dispatches** table.
- `boundary-violations` — the count of `VIOLATION` rows in the **Files Read** table.
- `bash-violations` — the count of `VIOLATION` rows in the **Bash Commands** table.
- `files-read-count` — the number of rows in the **Files Read** table.

`boundary-violations` and `bash-violations` are constraint-checks of the orchestrator's own activity against its allowlist (facts), not a self-evaluation. Never add self-grading fields such as `developer-quality`, `code-reviewer-speed`, `test-runner-reliability`, or `phase-difficulty` — the summary reports what the orchestrator did and observed, never a judgement of the agents it dispatched.
