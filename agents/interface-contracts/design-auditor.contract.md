# design-auditor Interface Contract

## Input

Provide the path to the feature directory.

**Required fields in prompt:**
```
Feature Path: [path to feature directory]
```

Ensure the feature directory contains:
- `specs/SDD.md` (the Software Design Document to validate)
- `specs/SRS.md` (required for traceability checks)

**Example:**
```
Validate the SDD at: .project/cycles/31-03-2026-credit-system/
```

The agent derives the specs directory as `<feature-dir>/specs/`, and the feature name as the basename of the feature directory.

## Output

The agent writes the audit report to disk, commits it path-scoped, and returns a structured message that includes a `Commit:` field. The dispatcher uses the presence of `Commit:` as the interrupted-commit recovery signal.

### Direct Return

#### VALID (Success)

```
Status: VALID
Commit: [short-hash | skipped | failed]
Feature: [feature name]
SDD: [SDD file path]
Report: [report file path]
Issues: 0 critical, 0 errors, [N] warnings, [N] info

[Optional: warning/info details if any]
```

#### INVALID (Failure)

```
Status: INVALID
Commit: [short-hash | skipped | failed]
Feature: [feature name]
SDD: [SDD file path]
Report: [report file path]
Issues: [N] critical, [N] errors, [N] warnings, [N] info

Issues:
1. [SEVERITY] (CONFIDENCE) Section: [section] — [issue description]
   Suggestion: [how to fix]
2. ...
```

`SEVERITY` is one of `CRITICAL | ERROR | WARNING | INFO`. `CONFIDENCE` is one of `HIGH | MEDIUM` — LOW-confidence findings are dropped during the auditor's self-check pass and never appear in the output.

#### Active-worktree refusal

When a worktree for the feature is live, the agent refuses without writing a report or running the audit:

```
Status: INVALID
Commit: none
Feature: [feature name]
SDD: [SDD file path]
Report: (not written)
Issues: 1 critical, 0 errors, 0 warnings, 0 info

Issues:
1. [CRITICAL] (HIGH) Section: (active-worktree check) — Worktree at <main-root>/.worktrees/<feature-name>/ is live; auditing the SDD on main while a worktree is in flight silently invalidates the worktree's inputs.
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

Written to: `<feature-dir>/specs/design-audit-report-attempt-[K].md`

Attempt number K is self-determined from the count of **tracked** matching reports plus one (`git ls-files '<specs-dir>/design-audit-report-attempt-*.md'`). Counting tracked-only makes K idempotent under interrupted-commit recovery — an attempt that was written but not committed is not tracked, so a re-dispatch computes the same K and finds the prior orphan at the target path. A legitimate re-audit after a successful prior run finds the prior attempt tracked and increments K, preserving the audit trail.

Successful, committed reports are never overwritten — they remain as immutable per-attempt files in the audit trail. The only path that re-uses a K is interrupted-commit recovery, where the agent recognizes its own incomplete prior attempt and either commits the existing file as-is (Write atomicity guarantees the file is complete if it exists at all) or overwrites with a fresh audit if no usable file is present.

The report contains the same information as the direct return, plus a step-by-step breakdown table showing how many issues each validation step found.

### Issues Format

Each issue contains:

| Field | Type | Description |
|-------|------|-------------|
| severity | `CRITICAL` \| `ERROR` \| `WARNING` \| `INFO` | Issue severity |
| confidence | `HIGH` \| `MEDIUM` | Evidence strength behind the finding (LOW is dropped before reporting) |
| section | string | SDD section where issue was found |
| issue | string | Description of the problem |
| suggestion | string | How to fix the problem |

### Confidence Definitions

| Confidence | Meaning |
|------------|---------|
| **HIGH** | Direct quote from the SDD, a named SRS FR-X with no SDD counterpart, or a concrete ambiguity in design prose |
| **MEDIUM** | Structural pattern mismatch (e.g., one DD-# missing a field that all others have; orphan diagram component) |

LOW-confidence findings (architectural taste, speculative scaling concerns, "feels wrong" judgments) are re-investigated once and dropped if they cannot reach MEDIUM. They never appear in the output — design critiques belong in design review, not in this structural audit.

### Severity Definitions

| Severity | Meaning | Effect on Status |
|----------|---------|-----------------|
| **CRITICAL** | SDD structurally broken (file missing, no design decisions) | INVALID |
| **ERROR** | Required element missing or wrong (FR-X missing from traceability, non-existent file path) | INVALID |
| **WARNING** | Suboptimal but usable (empty rationale, orphan DD-#, missing N/A explanation) | VALID (with warnings noted) |
| **INFO** | Suggestion for improvement (confidence level mismatch) | VALID |

## Validation Steps

The auditor executes 4 sequential steps:

| Step | Focus | What It Checks |
|------|-------|----------------|
| 1 | Structure | SDD title, required sections present and non-empty, Meta fields, Component Architecture table, DD-# presence and numbering, Traceability table structure |
| 2 | Traceability | Every SRS FR-X in traceability table, every traceability row references real FR-X, DD-# cross-references valid, SRS location format, orphan DD-# detection |
| 3 | Code References | Integration Points file paths exist, DD-# Rationale file references exist, Meta Source Spec path exists |
| 4 | Consistency | SDD/SRS scope alignment, rationale completeness, component-traceability alignment, confidence reasonableness, ASK-FIRST governance and Tech Stack Charter membership for DD-# and architecture/integration table rows |

## Recovery

The dispatcher (design-architect) uses the presence of the `Commit:` field in the return as the interrupted-commit recovery signal:

- A return with `Commit:` present (any value) → the agent ran to completion; the dispatcher proceeds.
- A return without `Commit:`, or no return at all (process killed mid-run, max-turns hit, hook-blocked stop) → the dispatcher re-dispatches the same invocation.

The re-dispatched agent is idempotent by construction:

- **K computation** is from `git ls-files` (tracked count + 1). An uncommitted prior attempt is not tracked, so K stays the same; a committed prior attempt is tracked, so K increments.
- **Existing-file check** at the K target path catches the common case (Write succeeded, commit didn't): the agent reads the prior complete report and commits it as-is rather than re-running the audit.
- **`commit-to-git` skipped semantics** catch the rarer case where re-running produces byte-identical content: no empty commit is forced.

The dispatcher must NOT re-dispatch on `Commit: failed` — the file is written and the commit failure is non-transient from the agent's perspective; a re-dispatch would loop on the same failure. Surface the failure to the user instead.

## Guarantees

- All 4 steps are always executed (no short-circuit on early failures) when a fresh audit runs; on interrupted-commit recovery from a complete prior attempt, the steps are not re-executed because the prior attempt's findings are already captured in the existing report file.
- Every file path claim is verified via Glob, not assumed
- Every finding includes the specific section where the issue was found
- Every finding includes a suggestion for how to fix
- Every reported finding carries a HIGH or MEDIUM confidence value; LOW-confidence findings are dropped during the self-check pass
- CRITICAL and ERROR findings pass a self-check (disconfirmation + severity calibration) before being reported
- Output format is consistent regardless of VALID/INVALID result
- A persistent report is written to `<feature-dir>/specs/design-audit-report-attempt-[K].md` with attempt numbering
- SRS line number accuracy is not validated (only format presence) because line numbers shift on SRS edits
- The agent never modifies SDD or SRS files — it only reads documents and writes its own report
- Commits **only** its own audit report — path-scoped, via the `commit-to-git` skill with `Agent: design-auditor`, after the report is written and before returning (subject `audit(<slug>): design audit attempt <K>`). Never stages or commits SDD, SRS, `ROADMAP.md`, or anything under `.project/product/`. This is the sole exception to its otherwise read-and-report-only write surface.
- Every return carries a `Commit:` field — a hash on successful commit, `skipped` when a re-dispatch produced byte-identical content, `failed` when the commit step failed despite a written report, or `none` on refusal paths where no report was written.
- Design Decisions, Component Architecture rows, and Integration Points rows are scanned for undeclared environment variables, packages, and infrastructure components. Any addition without an explicit user-approval marker (`User Approval:` inside the DD-#, `Requires User Approval: yes`, or SDD-level Meta `Infrastructure Additions Approved:`) produces an ERROR finding.
- Each such env var / package / infra component is additionally checked for membership in `.project/knowledge/tech-stack/charter.md` (read main-canonical): one not listed as `Approved` produces an `OFF_CHARTER_DEPENDENCY` ERROR finding (drives INVALID); an absent charter file produces a single `CHARTER_MISSING` WARNING. This charter check is the PRIMARY enforcement gate; the charter membership check and the approval-marker check are complementary and reported independently. `plan-auditor` repeats the charter check as a backstop.
