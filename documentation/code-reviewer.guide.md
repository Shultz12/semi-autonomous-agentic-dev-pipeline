# Code Reviewer Guide

## What It Does

The Code Reviewer agent validates code produced by the developer agent. It reads modified files, runs diagnostic commands, and produces a PASS verdict or a FAIL report with exact, actionable fix instructions. Every review — PASS or FAIL — lists what was checked.

**Model:** Claude Sonnet (`claude-sonnet-4-6`)

**Input:** A review request specifying the mode, review output directory, attempt number, and context (phase tasks, error output, or requirements) provided by the orchestrator.

**Output:** A standalone review file (one per attempt), committed path-scoped to the worktree, plus a structured message with verdict, commit hash, review file path, and summary of checks performed.

## Review Posture

The reviewer adopts a strict, by-the-book posture by design. It actively hunts for rule violations, grants no benefit of the doubt on style or convention, and applies each rule as written rather than rationalizing code into compliance. This is balanced by a self-check step that drops LOW-confidence findings (those not directly backed by tool output) before the review is reported — rigor here means thorough coverage, not inflated severities or fabricated issues.

Every finding in a FAIL report carries a Confidence level (HIGH or MEDIUM) alongside its Severity.

## When It Runs

Spawned by the orchestrator after developer phases complete, or when lint/build failures need diagnosis.

```
spec-architect -> design-architect -> plan-architect -> plan-auditor -> orchestrator -> developer -> [code-reviewer] -> testing
```

## Modes

| Mode | Trigger | Scope | Output |
|------|---------|-------|--------|
| **VERIFICATION_FAILURE** | Lint/build failed after 2 developer fix attempts | Modified files + error output | Diagnosis with exact fixes |
| **PHASE_REVIEW** | Developer reports SUCCESS for a phase | Modified files from that phase | PASS or FAIL with findings |
| **CYCLE_REVIEW** | All phases complete | All files across all phases | Cross-phase integration review |
| **INTEGRATION_VERIFICATION** | All phases complete | All files + requirements list | 3-level structural check (exists, substantive, wired) |
| **TEST_REVIEW** | Developer (test type) writes tests | Test files from that phase | PASS or FAIL with test-specific findings |
| **ABSTRACT_MIGRATION_REVIEW** | Phase carrying the `abstract-migration-phase` flag completes | Authored T1 (signature), T2 (codemod + tests), T5 (stragglers) — codemod-modified call-sites skipped unless tests fail | PASS or FAIL with migration-specific findings (Task field per finding) |

## File Naming

Each review attempt produces its own file. The code-reviewer constructs the filename from the trigger, phase, and attempt number:

| Trigger | Filename |
|---------|----------|
| PHASE_REVIEW, VERIFICATION_FAILURE | `phase-[N]-code-review-attempt-[K].md` |
| TEST_REVIEW | `phase-[N]-test-review-attempt-[K].md` |
| CYCLE_REVIEW | `cycle-review.md` |
| INTEGRATION_VERIFICATION | `integration-verification.md` |
| ABSTRACT_MIGRATION_REVIEW | `phase-[N]-abstract-migration-review-attempt-[K].md` |

If a file already exists at the constructed path, it is overwritten. The orchestrator owns the `Review Attempt` counter, so a same-K dispatch is an interrupted-commit re-dispatch whose deterministic output is safe to overwrite; the path-scoped commit naturally reports `skipped` when the overwrite produced no diff against HEAD.

## Invocation Notes

- The orchestrator provides a `Review Output Directory` (not a file path) — the code-reviewer constructs the filename
- The orchestrator passes `Prior Review Paths` listing all previous review files for the current phase, enabling the reviewer to focus on changes and detect bandaid fixes
- `Review Attempt` is used only for the filename and file body header — it does not change review behavior
- The code-reviewer never modifies code — it diagnoses and prescribes only
- Bash access is restricted to diagnostic commands (lint, build, type-check), directory creation, and committing the review file via the `commit-to-git` skill
- INTEGRATION_VERIFICATION does NOT run lint/build — it checks structural wiring via Glob/Read/Grep
- Both PASS and FAIL reviews include a list of checks performed
- The `Commit:` field in the return carries one of three values: `<short-hash>` (review file committed path-scoped), `skipped` (overwrite produced no diff against HEAD — the prior commit's content stands), or `failed` (commit step failed; the review file is on disk and the orchestrator must not re-dispatch — a re-dispatch would loop on the same failure). `none` is documented in the contract for enumeration completeness but never returned — the completion gate guarantees a review file is always written.
- The orchestrator treats the absence of `Commit:` in the return as an interrupted-commit recovery signal — a missing field (process killed, max-turns hit, hook-blocked stop) causes the orchestrator to re-dispatch the same invocation. The idempotent overwrite in the write step guarantees the re-dispatch reaches the same outcome.

## Related

- Agent definition: `.claude/agents/code-reviewer/code-reviewer.md`
- Interface contract: `.claude/agents/interface-contracts/code-reviewer.contract.md`
- Universal review rules: `.claude/agents/code-reviewer/essentials/review-rules.md`
- Integration checks: `.claude/agents/code-reviewer/essentials/integration-checks.md`
- Developer agent: `.claude/agents/developer/developer.md`
- Developer guide: `.claude/documentation/developer.guide.md`
