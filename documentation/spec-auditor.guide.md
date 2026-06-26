# Spec Auditor Guide

## What It Does

The Spec Auditor checks SRS and BDD specification documents for structural correctness before design-architect and plan-architect consume them. It catches missing sections, malformed requirement IDs, incomplete acceptance criteria, Gherkin syntax errors, and traceability gaps — preventing specification defects from propagating through the pipeline.

**Model:** Claude Sonnet

**Input:** Feature specs directory path (e.g., `.project/cycles/31-03-2026-feature/specs/`)

**Output:** `VALID` or `INVALID` result with a list of severity-tagged issues, plus a persistent report file that the auditor commits path-scoped before returning. The return carries a `Commit:` field (short-hash, `skipped`, `failed`, or `none`) that the dispatcher uses as the interrupted-commit recovery signal.

## When It Runs

Invoked after spec-architect produces SRS and BDD files. It sits in the pipeline between spec writing and architectural design:

```
spec-architect → spec-auditor → design-architect → plan-architect → plan-auditor
```

Common invocation:
```
Validate the specs at: .project/cycles/31-03-2026-credit-system/specs/
```

## What It Checks

The auditor runs 5 sequential validation steps:

| Step | What It Checks |
|------|---------------|
| **1. Structure** | SRS.md exists and has required sections, BDD directory has CONTEXT.md and primary .feature file, SRS frontmatter fields are valid |
| **2. Requirements** | FR-X IDs are sequential with valid priorities (P0/P1/P2), each requirement has acceptance criteria, user stories and edge cases documented |
| **3. BDD Validation** | CONTEXT.md has Domain Language, Actors, and other sections; .feature files have required tags (@domain, @priority, @layer); Gherkin syntax validated by gherkin-lint |
| **4. Traceability** | Every SRS functional requirement has at least one plausible BDD scenario (matched by domain keyword heuristic) |
| **5. Content Quality** | Flags vague language like "user-friendly", "fast" (without metrics), "etc." in requirements and acceptance criteria |

## Audit Posture

The Spec Auditor operates as a **strict, adversarial auditor**. It defaults to doubt rather than charity: ambiguous requirements, thin scenarios, and missing sections are flagged rather than rationalized into compliance. Rigor means every loaded rule gets checked against every spec file — it does not mean inflating severities or inventing issues the specs do not contain.

After running the 5 validation steps, the auditor runs a **Self-Check pass** on every CRITICAL and ERROR finding:

1. **Disconfirmation** — the finding must cite a direct quote, section reference, or cross-reference gap. Inferential findings get one re-investigation pass; if no stronger evidence surfaces, the finding is dropped.
2. **Severity calibration** — the assigned severity must match exactly what the rulebook specifies. No promotions to add weight, no demotions to soften the verdict.

### Confidence Column

Every emitted finding carries a **Confidence** value. It tells you how much you need to re-verify the finding before acting on it:

| Confidence | What It Means | How To Treat It |
|-----------|---------------|-----------------|
| **HIGH** | Direct quote, cross-reference gap, or gherkin-lint error line proves the defect | Act on the finding without re-verifying |
| **MEDIUM** | Structural or pattern inference from sibling sections (e.g., other FRs have acceptance criteria, this one does not) | Glance at the cited section to confirm the inference before rewriting |

LOW-confidence findings (interpretive taste calls) are dropped by the auditor and never reach you. If the auditor surfaces a finding, it has passed the evidence bar.

## Understanding Severity Levels

| Severity | Meaning | Impact |
|----------|---------|--------|
| **CRITICAL** | Spec is structurally broken (file missing, no requirements at all) | Makes result INVALID |
| **ERROR** | Required element missing (no acceptance criteria, missing BDD tags) | Makes result INVALID |
| **WARNING** | Suboptimal but usable (vague language, traceability gap, missing optional file) | Result stays VALID |
| **INFO** | Improvement suggestion (consider adding edge case file) | Result stays VALID |

## Understanding the Report

The auditor writes a persistent report to `<specs-dir>/spec-audit-report-attempt-[K].md` where K is the attempt number. K is derived from the count of **tracked** matching reports plus one — so each successful audit run gets a fresh K and the audit trail of committed reports is never overwritten. The report includes:

- Overall status (VALID/INVALID) with issue counts
- Issues grouped by severity, each with file, section, description, and fix suggestion
- Step-by-step summary showing how many issues each step found

After writing, the auditor commits the report path-scoped (via the `commit-to-git` skill) with subject `audit(<slug>): spec audit attempt <K>`. The commit names only the report file — no specification files, no other paths.

## Commit Behavior and the `Commit:` Field

Every return from the auditor carries a `Commit:` field:

| Value | Meaning |
|---|---|
| `<short-hash>` | The report was written and committed cleanly. |
| `skipped` | A re-dispatch produced byte-identical content to HEAD; no new commit was made. |
| `failed` | The commit step failed despite a successful write. The report file exists on disk and can be committed manually. The dispatcher will not auto-retry — investigate before re-running. |
| `none` | No report was written this invocation. Currently this happens only on the active-worktree refusal path. |

## Interrupted-Commit Recovery

If the auditor's process is killed between writing the report and committing it (transient error, max-turns, hook-blocked stop), the dispatcher (spec-architect) re-dispatches the same invocation. The recovery is built into the workflow:

1. **K stays the same** under recovery because K is computed from `git ls-files` (tracked count + 1) — the orphaned prior attempt is not tracked, so it does not bump K.
2. **The existing file is recognized** — the Write tool is atomic, so any file at the target path is a complete report from the prior run; the auditor reads it, skips the audit work, and commits the existing file as-is.
3. **`commit-to-git` reports `skipped`** if a fresh audit happens to produce byte-identical content, avoiding empty commits.

This means re-dispatches are cheap (no redundant LLM audit work in the common case) and idempotent (the final state on disk is the same regardless of how many times recovery fires).

## Gherkin Syntax Validation

The auditor uses `gherkin-lint` (via `npx gherkin-lint`) to validate .feature file syntax. This catches structural Gherkin issues that would be expensive for the LLM to pattern-match.

If gherkin-lint is not installed, the auditor records a WARNING and skips syntax validation. To enable it:

```bash
npm install -D gherkin-lint
```

## Traceability Checking

Traceability between SRS requirements and BDD scenarios is checked via keyword heuristics. The auditor extracts key domain terms from each FR-X requirement name and acceptance criteria, then searches .feature files for those terms.

This is a best-effort check — BDD scenarios intentionally use business language rather than FR-X IDs. False positives are possible when scenarios use different phrasing. All traceability findings are WARNING-severity (never blocking).

## Limitations

- Does not validate whether specs capture the right product intent — that's the user's judgment
- Does not validate technical feasibility — that's design-architect's job
- Does not validate SDD (Software Design Document) — that will be design-auditor's job
- Traceability checking is heuristic-based and may produce false positives
- Gherkin validation requires gherkin-lint to be installed; degrades gracefully if unavailable
- Vague language detection uses pattern matching and may flag terms used in acceptable context
- Bash usage is limited to gherkin-lint, the `git ls-files` query for the attempt counter, the `echo` that registers the output target, and the path-scoped `git add`/`git commit` form supplied by the `commit-to-git` skill — no other shell commands

## Related

- Agent definition: `.claude/agents/spec-auditor/spec-auditor.md`
- Interface contract: `.claude/agents/interface-contracts/spec-auditor.contract.md`
- Validation rules: `.claude/agents/spec-auditor/essentials/spec-review-rules.md`
- SRS template (what SRS should look like): `.claude/skills/spec-architect/reference/srs-template.md`
- BDD template (what BDD should look like): `.claude/skills/spec-architect/reference/bdd-template.md`
