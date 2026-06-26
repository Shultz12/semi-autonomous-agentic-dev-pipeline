# Design Auditor Guide

## What It Does

The Design Auditor validates Software Design Documents (SDDs) for structural correctness before plan-architect consumes them. It catches missing sections, broken traceability between SRS requirements and design decisions, non-existent file references, and internal inconsistencies — preventing design defects from propagating through the pipeline. The auditor also writes a persistent report and commits it path-scoped before returning, so the audit trail is preserved in git history.

**Model:** Claude Sonnet

**Input:** Feature directory path (e.g., `.project/cycles/31-03-2026-feature/`)

**Output:** `VALID` or `INVALID` result with a list of severity-tagged issues, a `Commit:` field carrying the commit hash (or `skipped` / `failed` / `none`), and a persistent report file.

## When It Runs

Invoked after design-architect produces the SDD. It sits in the pipeline between architectural design and implementation planning:

```
spec-architect → spec-auditor → design-architect → design-auditor → plan-architect → plan-auditor
```

Common invocation:
```
Validate the SDD at: .project/cycles/31-03-2026-credit-system/
```

If a worktree for the feature is already live (`.worktrees/<feature-name>/` exists), the auditor refuses to run: re-auditing the SDD on main while the worktree's plan was already written against it would silently invalidate the worktree's inputs. The refusal returns `Status: INVALID`, `Commit: none`, and a single CRITICAL finding pointing the caller to `/accept-feature`+amend or `/abandon-feature`+restart.

## What It Checks

The auditor runs 4 sequential validation steps:

| Step | What It Checks |
|------|---------------|
| **1. Structure** | SDD has all required sections (Meta, Design Overview, Component Architecture, Design Decisions, etc.), Meta fields are complete, Design Confidence is valid, DD-# numbering is sequential, tables have correct columns and data |
| **2. Traceability** | Every SRS FR-X appears in the Requirement Traceability table, every traceability row references a real FR-X, DD-# cross-references are valid, SRS location uses correct format, orphan DD-# detected |
| **3. Code References** | Integration Points file paths verified via Glob, DD-# Rationale file references verified, Meta Source Spec path verified |
| **4. Consistency** | SDD scope doesn't contradict SRS scope, design decision rationales are non-empty, component names align between architecture and traceability tables, confidence level reasonableness; DD-#, Component Architecture rows, and Integration Points rows scanned for undeclared env vars, packages, or infra without user-approval markers (ASK-FIRST governance) |

## Audit Posture

The design-auditor takes an adversarial, default-to-doubt stance toward the SDD. Its job is to surface structural defects, not to endorse designs. Every loaded rule is checked against every SDD section and every SRS cross-reference; a VALID verdict reflects coverage, not surface reading. Severities are not inflated — they stay as `design-review-rules.md` defines them.

Each finding carries a **Confidence** value alongside its severity:

| Confidence | Evidence Standard |
|------------|-------------------|
| **HIGH** | A direct quote from the SDD that exhibits the defect, a named SRS FR-X with no SDD counterpart, or a concrete ambiguity in design prose (e.g., "the system processes the request" with no named component) |
| **MEDIUM** | A structural pattern mismatch (e.g., one DD-# missing a Rationale field that all others have; a component that appears in the architecture diagram but not in the prose) |

LOW-confidence findings — architectural taste calls, speculative scaling concerns, "this coupling feels wrong" — are re-investigated once and dropped if they cannot reach MEDIUM. They never appear in the report. Design critiques of that kind belong in design review with a human, not in a structural audit. Rigor here means coverage and calibration, not severity inflation or invented findings.

## Understanding Severity Levels

| Severity | Meaning | Impact |
|----------|---------|--------|
| **CRITICAL** | SDD is structurally broken (file missing, no design decisions at all) | Makes result INVALID |
| **ERROR** | Required element missing (FR-X not in traceability, Integration Points references non-existent file) | Makes result INVALID |
| **WARNING** | Suboptimal but usable (empty rationale, orphan DD-#, missing N/A explanation) | Result stays VALID |
| **INFO** | Improvement suggestion (confidence level may be inaccurate) | Result stays VALID |

## Understanding the Report

The auditor writes a persistent report to `<feature-dir>/specs/design-audit-report-attempt-[K].md` where K is the attempt number, computed from the count of **tracked** prior reports (`git ls-files`) plus one. Successful committed reports are never overwritten — each audit run produces a new tracked attempt file in the audit trail. The only path that re-uses a K is interrupted-commit recovery (see below).

The report includes:

- Overall status (VALID/INVALID) with issue counts
- Issues grouped by severity, each with section, description, and fix suggestion
- Step-by-step summary showing how many issues each step found

## Commit Behavior

After the report is written, the auditor commits it path-scoped via the `commit-to-git` skill with `Agent: design-auditor` and subject `audit(<slug>): design audit attempt <K>` (where `<slug>` is the basename of the feature directory). Only the report file is staged — no SDD, SRS, or unrelated changes are pulled in.

The return includes a `Commit:` field that downstream consumers use to confirm the commit landed:

| `Commit:` Value | Meaning |
|---|---|
| `<short-hash>` | The report was written and committed successfully. |
| `skipped` | A re-dispatch produced byte-identical content to HEAD; no commit was made. The prior commit's content is the source of truth. |
| `failed` | The commit step failed (lock contention, hook rejection, transient error). The report file exists on disk and can be committed manually. The dispatcher should investigate; do not re-dispatch on `failed`. |
| `none` | No artifact was written. Emitted only on the active-worktree refusal path. |

## Interrupted-Commit Recovery

If the auditor's process is killed between writing the report and completing the commit (max-turns hit, hook-blocked stop, transient crash), the dispatcher detects the missing return (or a return without a `Commit:` field) and re-dispatches the same invocation. The recovery model is implicit — there is no separate "resume" mode.

Three mechanisms make the re-dispatch produce a clean outcome:

1. **K from tracked count.** K is computed from `git ls-files` of prior reports, so an uncommitted prior attempt is not counted. The re-dispatch computes the same K and lands at the same target path.
2. **Existing-file recognition.** Before re-running the audit, the agent checks the target path. If a complete report file already exists there (Write tool atomicity guarantees completeness if the file exists at all), the agent reads it, extracts the status and issues, and commits the existing file as-is rather than re-running the 4-step audit.
3. **`commit-to-git` skipped semantics.** If a rare case produces byte-identical content to HEAD, the skill reports `skipped` rather than forcing an empty commit.

The dispatcher does not re-dispatch on `Commit: failed` — the file is written and the failure is persistent from the agent's perspective; a retry would loop on the same failure. The user resolves a `failed` commit by inspecting the cause (lock contention, hook output) and committing manually.

## Traceability Checking

Unlike spec-auditor's heuristic keyword matching (SRS↔BDD), design-auditor performs exact ID matching for traceability. The SDD's Requirement Traceability table explicitly maps FR-X IDs to components and design decisions, enabling precise forward and backward verification.

SRS line numbers (`SRS.md:L##`) are checked for format presence only — not accuracy. Line numbers shift when the SRS is edited, so the auditor verifies the format pattern exists but does not read the SRS at those specific line numbers.

## Limitations

- Does not validate technical feasibility of design decisions — that's the user's judgment
- Does not validate code quality
- Does not validate SRS or BDD specs
- SRS line number accuracy is not checked (only format presence)
- Scope boundary alignment (Step 4) flags only clear contradictions, not subtle mismatches
- File path verification checks existence only, not whether the referenced code is appropriate for the stated integration
- Bash access is limited to `git ls-files` (attempt counter), `echo` (output target registration), and `git add`/`git commit` (via the `commit-to-git` skill). The auditor does not run linters, tests, or arbitrary shell commands.

## Related

- Agent definition: `.claude/agents/design-auditor/design-auditor.md`
- Interface contract: `.claude/agents/interface-contracts/design-auditor.contract.md`
- Validation rules: `.claude/agents/design-auditor/essentials/design-review-rules.md`
- SDD template (what SDD should look like): `.claude/skills/design-architect/reference/sdd-template.md`
- Design-architect skill: `.claude/skills/design-architect/SKILL.md`
- Spec-auditor (sibling): `.claude/agents/spec-auditor/spec-auditor.md`
- Plan-auditor (sibling): `.claude/agents/plan-auditor/plan-auditor.md`
