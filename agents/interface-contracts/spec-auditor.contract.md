# spec-auditor Interface Contract

## Input

Provide the path to the feature specs directory.

**Required fields in prompt:**
```
Specs Path: [path to feature specs directory]
```

Ensure the specs directory contains:
- `SRS.md` at the top level
- `bdd/` subdirectory with `CONTEXT.md` and at least one `.feature` file

**Example:**
```
Validate the specs at: .project/cycles/31-03-2026-credit-system/specs/
```

The agent extracts the feature name from the SRS frontmatter `feature` field to locate the primary `.feature` file (`bdd/<feature-name>.feature`).

## Output

The agent writes the audit report to disk, commits it path-scoped, and returns a structured message that includes a `Commit:` field. The dispatcher uses the presence of `Commit:` as the interrupted-commit recovery signal.

### Direct Return

#### VALID (Success)

```
Status: VALID
Commit: [short-hash | skipped | failed]
Feature: [feature name]
Specs: [specs directory path]
Report: [report file path]
Issues: 0 critical, 0 errors, [N] warnings, [N] info

[Optional: warning/info details if any]
```

#### INVALID (Failure)

```
Status: INVALID
Commit: [short-hash | skipped | failed]
Feature: [feature name]
Specs: [specs directory path]
Report: [report file path]
Issues: [N] critical, [N] errors, [N] warnings, [N] info

Issues:
1. [SEVERITY | CONFIDENCE] File: [file] Section: [section] — [issue description]
   Evidence: [direct quote, section reference, or tool-output excerpt]
   Suggestion: [how to fix]
2. ...
```

#### Active-worktree refusal

When a worktree for the feature is live, the agent refuses without writing a report or running the audit:

```
Status: INVALID
Commit: none
Feature: [feature name]
Specs: [specs directory path]
Report: (not written)
Issues: 1 critical, 0 errors, 0 warnings, 0 info

Issues:
1. [CRITICAL | HIGH] File: (specs directory) Section: (active-worktree check) — Worktree at <main-root>/.worktrees/<feature-name>/ is live; auditing specs on main while a worktree is in flight silently invalidates the worktree's inputs.
   Suggestion: Either finish execution and amend post-acceptance (producing a <feature>-amend-N artifact) or run /abandon-feature and restart.
```

### `Commit:` Field Semantics

| Value | Meaning |
|---|---|
| `<short-hash>` | The report was written and successfully committed path-scoped. |
| `skipped` | A re-dispatch produced byte-identical content to HEAD; no commit was made. The prior commit's content is the source of truth. |
| `failed` | The commit step failed (lock contention, hook rejection, transient error). The report file exists on disk and can be committed manually. The dispatcher should investigate; it must not re-dispatch on `failed` (the file is written, so a re-dispatch would loop on the same failure). |
| `none` | No artifact was written this invocation. Currently emitted only on the active-worktree refusal path. |

### Written Report

Written to: `<specs-dir>/spec-audit-report-attempt-[K].md`

Attempt number K is self-determined from the count of **tracked** matching reports plus one (`git ls-files '<specs-dir>/spec-audit-report-attempt-*.md'`). Counting tracked-only makes K idempotent under interrupted-commit recovery — an attempt that was written but not committed is not tracked, so a re-dispatch computes the same K and finds the prior orphan at the target path. A legitimate re-audit after a successful prior run finds the prior attempt tracked and increments K, preserving the audit trail.

Successful, committed reports are never overwritten — they remain as immutable per-attempt files in the audit trail. The only path that re-uses a K is interrupted-commit recovery, where the agent recognizes its own incomplete prior attempt and either commits the existing file as-is (Write atomicity guarantees the file is complete if it exists at all) or overwrites with a fresh audit if no usable file is present.

The report contains the same information as the direct return, plus a step-by-step breakdown table showing how many issues each validation step found.

### Issues Format

Each issue contains:

| Field | Type | Description |
|-------|------|-------------|
| severity | `CRITICAL` \| `ERROR` \| `WARNING` \| `INFO` | Issue severity |
| confidence | `HIGH` \| `MEDIUM` | Evidence strength — see Evidence Standards below |
| file | string | Which file the issue was found in (SRS.md, CONTEXT.md, or .feature file) |
| section | string | Section or element where issue was found |
| issue | string | Description of the problem |
| evidence | string | Direct quote, section reference, or tool-output excerpt substantiating the finding (required on CRITICAL and ERROR) |
| suggestion | string | How to fix the problem |

### Severity Definitions

| Severity | Meaning | Effect on Status |
|----------|---------|-----------------|
| **CRITICAL** | Document structurally broken (missing file, no requirements) | INVALID |
| **ERROR** | Required element missing or wrong (no acceptance criteria, missing tags) | INVALID |
| **WARNING** | Suboptimal but usable (vague language, missing optional file, traceability gap) | VALID (with warnings noted) |
| **INFO** | Suggestion for improvement (missing optional section) | VALID |

### Evidence Standards (Confidence)

Every finding carries a Confidence value. The auditor drops any finding that cannot reach at least MEDIUM after one re-investigation pass.

| Confidence | Evidence | Downstream Consumer Reads As |
|-----------|----------|------------------------------|
| **HIGH** | Direct quote from the spec that exhibits the defect, or an explicit cross-reference gap shown by Read/Grep, or a gherkin-lint error line | Act on the finding without re-verification |
| **MEDIUM** | Structural or pattern-level mismatch inferred from sibling sections (e.g., other FRs have acceptance criteria, this one does not) | Glance at the cited section to confirm the inference before rewriting |
| **LOW (not emitted)** | Interpretive taste calls ("this feels too general") | Dropped by the auditor; never reaches the consumer |

## Validation Steps

The auditor executes 5 sequential validation steps and then a Self-Check phase before compiling the result:

| Step | Focus | What It Checks |
|------|-------|----------------|
| 1 | Structure | File presence (SRS, CONTEXT.md, .feature), SRS frontmatter, section headings |
| 2 | Requirements | FR-X IDs, sequential numbering, priority tags, acceptance criteria, user stories |
| 3 | BDD Validation | CONTEXT.md sections, .feature structure, tags, Gherkin syntax via gherkin-lint |
| 4 | Traceability | SRS↔BDD coverage (keyword heuristic for each FR-X) |
| 5 | Content Quality | Vague language detection in functional and non-functional requirements |

After the 5 steps, a Self-Check phase re-examines every CRITICAL and ERROR finding for disconfirmation (evidence must directly prove the defect) and severity calibration (severity must match what `spec-review-rules.md` specifies). Findings that cannot reach HIGH or MEDIUM confidence after one re-investigation pass are dropped.

## Recovery

The dispatcher (spec-architect) uses the presence of the `Commit:` field in the return as the interrupted-commit recovery signal:

- A return with `Commit:` present (any value) → the agent ran to completion; the dispatcher proceeds.
- A return without `Commit:`, or no return at all (process killed mid-run, max-turns hit, hook-blocked stop) → the dispatcher re-dispatches the same invocation.

The re-dispatched agent is idempotent by construction:

- **K computation** is from `git ls-files` (tracked count + 1). An uncommitted prior attempt is not tracked, so K stays the same; a committed prior attempt is tracked, so K increments.
- **Existing-file check** at the K target path catches the common case (Write succeeded, commit didn't): the agent reads the prior complete report and commits it as-is rather than re-running the audit.
- **`commit-to-git` skipped semantics** catch the rarer case where re-running produces byte-identical content: no empty commit is forced.

The dispatcher must NOT re-dispatch on `Commit: failed` — the file is written and the commit failure is non-transient from the agent's perspective; a re-dispatch would loop on the same failure. Surface the failure to the user instead.

## Guarantees

- All 5 steps are always executed (no short-circuit on early failures) when a fresh audit runs; on interrupted-commit recovery from a complete prior attempt, the steps are not re-executed because the prior attempt's findings are already captured in the existing report file.
- Every CRITICAL and ERROR finding passes a Self-Check for evidence and severity calibration before being reported
- Every emitted finding carries a Confidence value of HIGH or MEDIUM; LOW-confidence findings are dropped rather than surfaced
- Severities are assigned exactly as `spec-review-rules.md` specifies — not inflated to add weight, not deflated to soften the verdict
- Gherkin syntax is validated by gherkin-lint, not LLM pattern-matching; if gherkin-lint is unavailable, a WARNING is recorded and syntax checks are skipped
- Every finding includes the specific file and section where the issue was found
- Every finding includes a suggestion for how to fix
- Output format is consistent regardless of VALID/INVALID result
- A persistent report is written to `<specs-dir>/spec-audit-report-attempt-[K].md` with attempt numbering
- Traceability checks use keyword heuristics and are WARNING-severity (never blocking)
- The agent never modifies specification files — it only reads specs and writes its own report
- Commits **only** its own audit report — path-scoped, via the `commit-to-git` skill with `Agent: spec-auditor`, after the report is written and before returning (subject `audit(<slug>): spec audit attempt <K>`). Never stages or commits specification files, `ROADMAP.md`, or anything under `.project/product/`. This is the sole exception to its otherwise read-and-report-only write surface.
- Every return carries a `Commit:` field — a hash on successful commit, `skipped` when a re-dispatch produced byte-identical content, `failed` when the commit step failed despite a written report, or `none` on refusal paths where no report was written.
