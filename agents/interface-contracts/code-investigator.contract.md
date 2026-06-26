# code-investigator Interface Contract

## Input — Investigation Mode

After test-runner reports FAIL or code-reviewer findings need deeper analysis.

**Required:**
```
Mode: investigation
Trigger: TEST_FAILURE | CODE_REVIEW_FAILURE
Cycle: [cycle-slug]
Phase: [N]: [phase-name]
Cycle Path: [.project/cycles/<cycle>/]
Investigation Output Path: [path to execution/code-investigations/phase-N-{code|test}-investigation-{attempt}.md]
Investigation Attempt: [N — from orchestrator's attempt counter]
Minimum Depth: [0-3, default 0 — set higher on re-investigation to skip already-loaded context]
Plan Path: [path to implementation-plan.md]
Manifest Path: [path to execution/manifest.md]
```

**TEST_FAILURE additionally requires:**
```
Test Results Path: [path to execution/test-results/phase-N-results.md]
Implementation Report: [path to implementation developer report]
  → Read `## Files Modified` and `## Artifacts Produced` sections
Test Report: [path to test developer report]
  → Read `## Files Modified` section
```

**CODE_REVIEW_FAILURE additionally requires:**
```
Code Review Path: [path to execution/code-reviews/phase-N-code-review-attempt-K.md]
Developer Report: [path to developer report]
  → Read `## Files Modified` and `## Artifacts Produced` sections for file scope
```

**STANDALONE_BUG (no phase context) — does NOT use the shared Required block above; it carries its own complete input set:**
```
Mode: investigation
Trigger: STANDALONE_BUG
Cycle: [bugfix slug, e.g. 19-04-2026-fix-hebrew-date-parse-crash]
Cycle Path: [.project/cycles/<slug>/]
Bug Report: [path to specs/bug-report.md]
Investigation Output Path: [path to execution/code-investigations/<DD-MM-YYYY>-HH-MM-investigation.md]
Investigation Attempt: [N — from orchestrator's attempt counter]
Minimum Depth: [0-3, default 0 — set higher on re-investigation to skip already-loaded context]
```
`STANDALONE_BUG` carries no `Phase`, `Plan Path`, or `Manifest Path` — no plan exists when Stage 1 of a bug fix dispatches the investigator.

**Behavioral path additionally provides (when the reproduction artifacts exist):**
```
Reproduction Test Report: [path to execution/developer-reports/reproduction-test-report.md]
Reproduction Results: [path to execution/test-results/reproduction-results.md]
```
Absent when the orchestrator runs investigate-first (the investigator works from the bug report plus any logs in its `## Attached Output`).

**Tool-oracle path additionally provides:**
```
Failing Commands: [one shell command per line — the investigator runs each and captures the output in its own context]
```

### Example Invocation — TEST_FAILURE

```
Mode: investigation
Trigger: TEST_FAILURE
Phase: 2: Implement notification delivery service
Cycle Path: .project/cycles/15-03-2026-notification-system/
Investigation Output Path: .project/cycles/15-03-2026-notification-system/execution/code-investigations/phase-2-test-investigation-1.md
Investigation Attempt: 1
Minimum Depth: 0
Plan Path: .project/cycles/15-03-2026-notification-system/plans/implementation-plan.md
Manifest Path: .project/cycles/15-03-2026-notification-system/execution/manifest.md
Test Results Path: .project/cycles/15-03-2026-notification-system/execution/test-results/phase-2-results.md
Implementation Report: .project/cycles/15-03-2026-notification-system/execution/developer-reports/phase-2-implementation-report.md
  → Read `## Files Modified` and `## Artifacts Produced` sections
Test Report: .project/cycles/15-03-2026-notification-system/execution/developer-reports/phase-2-test-report.md
  → Read `## Files Modified` section
```

### Example Invocation — CODE_REVIEW_FAILURE

```
Mode: investigation
Trigger: CODE_REVIEW_FAILURE
Phase: 2: Implement notification delivery service
Cycle Path: .project/cycles/15-03-2026-notification-system/
Investigation Output Path: .project/cycles/15-03-2026-notification-system/execution/code-investigations/phase-2-code-investigation-1.md
Investigation Attempt: 1
Minimum Depth: 0
Plan Path: .project/cycles/15-03-2026-notification-system/plans/implementation-plan.md
Manifest Path: .project/cycles/15-03-2026-notification-system/execution/manifest.md
Code Review Path: .project/cycles/15-03-2026-notification-system/execution/code-reviews/phase-2-code-review-attempt-2.md
Developer Report: .project/cycles/15-03-2026-notification-system/execution/developer-reports/phase-2-implementation-report.md
  → Read `## Files Modified` and `## Artifacts Produced` sections for file scope
```

### Example Invocation — STANDALONE_BUG (behavioral, reproduce-first)

```
Mode: investigation
Trigger: STANDALONE_BUG
Cycle: 19-04-2026-fix-hebrew-date-parse-crash
Cycle Path: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/
Bug Report: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/specs/bug-report.md
Investigation Output Path: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/execution/code-investigations/19-04-2026-14-30-investigation.md
Investigation Attempt: 1
Minimum Depth: 0
Reproduction Test Report: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/execution/developer-reports/reproduction-test-report.md
Reproduction Results: .project/cycles/19-04-2026-fix-hebrew-date-parse-crash/execution/test-results/reproduction-results.md
```

### Example Invocation — STANDALONE_BUG (tool-oracle, failing build)

```
Mode: investigation
Trigger: STANDALONE_BUG
Cycle: 19-04-2026-fix-build-type-error-credit-service
Cycle Path: .project/cycles/19-04-2026-fix-build-type-error-credit-service/
Bug Report: .project/cycles/19-04-2026-fix-build-type-error-credit-service/specs/bug-report.md
Investigation Output Path: .project/cycles/19-04-2026-fix-build-type-error-credit-service/execution/code-investigations/19-04-2026-09-12-investigation.md
Investigation Attempt: 1
Minimum Depth: 0
Failing Commands: pnpm --filter @app/credit-service build
```

## Input — Resolution Mode

When user provides a decision for a Level 3 or Level 4 finding.

**Required:**
```
Mode: resolution
Phase: [N]: [phase-name]
Investigation File Path: [path to existing investigation file]
Level: LEVEL_3 | LEVEL_4
Resolution: [user's chosen option name (LEVEL_3) or decision text (LEVEL_4)]
Rationale: [user's reasoning, or "Not provided"]
```

### Example Invocation — Resolution

```
Mode: resolution
Phase: 2: Implement notification delivery service
Investigation File Path: .project/cycles/15-03-2026-notification-system/execution/code-investigations/phase-2-test-investigation-1.md
Level: LEVEL_3
Resolution: Option A — Use event-driven notification dispatch
Rationale: Aligns better with our async processing patterns and keeps the controller thin
```

## Output

The code-investigator writes an investigation file to `Investigation Output Path` (investigation mode) or appends a resolution section to the file at `Investigation File Path` (resolution mode), commits it path-scoped, and returns a structured message. The investigation file is the source of truth for downstream agents (developer fix mode, quality-analyst); the message provides routing data — including the commit signal — for the orchestrator.

### Investigation File Format

Every investigation file starts with YAML frontmatter:

```yaml
---
verdict: LEVEL_1 | LEVEL_2 | LEVEL_3 | LEVEL_4 | ACCEPTED_FAILURE | CANNOT_REPRODUCE
confidence: HIGH | MEDIUM
target: code | test | n/a
phase: [N] | n/a
cycle: <slug>
trigger: TEST_FAILURE | CODE_REVIEW_FAILURE | STANDALONE_BUG
---
```

`CANNOT_REPRODUCE` is a `STANDALONE_BUG`-only verdict (`confidence: HIGH`, `target: n/a`, `phase: n/a`) — the investigator ran the oracle, found no defect, and no cause surfaced after exhausting depth.

The body contains root cause analysis, fix instructions, options (Level 3), or competing hypotheses (Level 4), depending on verdict.

**STANDALONE_BUG rendering.** A `STANDALONE_BUG` investigation has no phase: the frontmatter sets `phase: n/a` and the body title is `# Investigation — <bug summary>` rather than `# Phase [N] Investigation — [Phase Name]`. The filename is timestamped — `<DD-MM-YYYY>-HH-MM-investigation.md` under `<Cycle Path>/execution/code-investigations/`. The body adds one scenario-specific section beyond the standard Root Cause / Fix Instructions / Evidence:
- **Behavioral** — `### Deterministic reproduction conditions`: the conditions under which the bug reliably triggers (so the reproduction test can be made reliably-failing).
- **Tool-oracle** — `### Diagnosed error clusters`: the build/lint/type errors grouped; when clusters are independent and large, each is sketched here for the fan-out dispatch.

A `STANDALONE_BUG` investigation resolves to one of three outcomes: (1) a severity verdict (LEVEL_1–LEVEL_4); (2) a severity verdict carrying `Scenario-Reclassification` when the reported scenario class is wrong but a cause was still found (the cause is re-routed, never discarded); or (3) `CANNOT_REPRODUCE` when the oracle manifests no defect and no cause surfaces after exhausting depth. A `CANNOT_REPRODUCE` file omits Fix Instructions and instead documents what was run, the clean result, and why it is not a defect; its title is `# Investigation — <bug summary>` and frontmatter `verdict: CANNOT_REPRODUCE`.

### Message to Orchestrator

**Investigation mode (LEVEL_1 / LEVEL_2):**
```
Verdict: LEVEL_1 | LEVEL_2
Confidence: HIGH | MEDIUM
Target: code | test (TEST_FAILURE trigger only)
Investigation File: [path]
Commit: [short-hash | skipped | failed]
```

**Investigation mode (LEVEL_3):**
```
Verdict: LEVEL_3
Confidence: HIGH | MEDIUM
Investigation File: [path]
Commit: [short-hash | skipped | failed]
Root Cause: [summary]
Options: [numbered list with tradeoffs]
Recommendation: [which option and why]
```

**Investigation mode (LEVEL_4):**
```
Verdict: LEVEL_4
Confidence: HIGH
Investigation File: [path]
Commit: [short-hash | skipped | failed]
Investigation Exhausted: [what was tried and why it's inconclusive]
Competing Hypotheses: [numbered list with evidence for/against]
What Would Resolve This: [what information or decision is needed]
```

**Investigation mode (ACCEPTED_FAILURE):**
```
Verdict: ACCEPTED_FAILURE
Investigation File: [path]
Commit: [short-hash | skipped | failed]
Root Cause: [why this failure is expected/acceptable]
```

**Investigation mode (CANNOT_REPRODUCE)** (STANDALONE_BUG only — the oracle shows no defect and no cause surfaces):
```
Verdict: CANNOT_REPRODUCE
Confidence: HIGH
Investigation File: [path]
Commit: [short-hash | skipped | failed]
Summary: [one line — the reported failure does not reproduce in a clean worktree at <commit>]
```

**STANDALONE_BUG return additions.** A `STANDALONE_BUG` **severity** return (LEVEL_1–LEVEL_4) may carry two optional flag lines (a `CANNOT_REPRODUCE` return never carries them):
```
Scenario-Reclassification: <build | lint | type | crash | logic>
Fan-Out-Recommended: true
```
- `Scenario-Reclassification:` — the bug report's scenario class is wrong (e.g. a build error masking a behavioral defect, or a passing build that nonetheless hides a logic defect); the cause is established but belongs on the other path, so the orchestrator re-routes it. Omitted when the scenario holds.
- `Fan-Out-Recommended: true` — the error clusters are genuinely independent and large; the orchestrator dispatches one additional investigator per cluster (each with its own distinct `Investigation Output Path`), using the per-cluster sketch in the body. Omitted/`false` when one investigator suffices.

**Resolution mode (SUCCESS):**
```
Reporter: code-investigator
Mode: resolution
Phase: [N]: [phase-name]
Original Verdict: LEVEL_3 | LEVEL_4
Resolution: [chosen option or decision summary]
Investigation File: [path]
Commit: [short-hash | skipped | failed]
Target: code | test

### Fix Summary
[count] fixes in [count] files. [1 sentence overview]

### Verification
- [commands to confirm fix]
```

**Resolution mode (INSUFFICIENT)** (LEVEL_4 only — user input doesn't translate to fixes):
```
Reporter: code-investigator
Mode: resolution
Phase: [N]: [phase-name]
Original Verdict: LEVEL_4
Status: INSUFFICIENT
Investigation File: [path]
Commit: none

### What's Missing
[1-2 sentences: what additional input is needed to formulate fixes]
```

`Commit:` semantics:

| Value | Meaning |
|---|---|
| `<short-hash>` | The investigation file was written and successfully committed path-scoped to the worktree. |
| `skipped` | The write produced no diff against HEAD (a re-dispatch reproduced byte-identical content). No commit was made — the prior commit's content is the source of truth. |
| `failed` | The commit step failed (lock contention, hook rejection, transient error). The investigation file exists on disk; manual investigation required. |
| `none` | No write occurred (resolution mode only — INSUFFICIENT verdict or pre-validation failure). Nothing to commit. |

## Recovery

If the orchestrator's dispatch returns without a `Commit:` field (process killed mid-run, max-turns hit, hook-blocked stop, no return at all), the orchestrator re-dispatches the same invocation. code-investigator normalizes the target file to a known starting state before writing — `git checkout HEAD -- <path>` if the file is tracked at HEAD (discards uncommitted changes from a crashed prior attempt), or `rm` if untracked (the orphan was never in the audit trail), or no-op if absent. The re-dispatched attempt then writes fresh (investigation mode — one file per attempt) or re-appends the resolution (resolution mode), and commits. The orchestrator does NOT re-dispatch on `Commit: failed` — the file is written and a re-dispatch would loop on the same failure.

## Severity Levels

| Level | Name | Criteria | Downstream Action |
|-------|------|----------|-------------------|
| LEVEL_1 | Local | Single file, clear root cause | Developer fixes with exact instructions |
| LEVEL_2 | Cross-cutting | Multiple files/layers, clear approach | Developer fixes with multi-file instructions |
| LEVEL_3 | Design decision | Multiple valid approaches with tradeoffs | User chooses, then resolution mode |
| LEVEL_4 | Human judgment | Investigation exhausted, multiple hypotheses remain | User evaluates, then resolution mode |

`CANNOT_REPRODUCE` (STANDALONE_BUG only) is not a severity level — it is a terminal "no defect found" outcome: the oracle passes and no cause surfaces after exhausting depth. Downstream action: the orchestrator surfaces "cannot reproduce" to the user and parks the bug fix; no fix is planned. Distinct from LEVEL_4, where a cause exists but cannot be singled out.

`ACCEPTED_FAILURE` (TEST_FAILURE only) is likewise not a severity level — it is a terminal outcome where independent verification rules out both a CODE_BUG and a TEST_BUG and the failing test is judged defensible to accept (intentionally unimplemented behaviour, a deferred decision, or a dropped requirement). Downstream action: the orchestrator presents the root cause to the user; on confirmation the test is marked skipped with an inline reason and re-run, on rejection the failure is re-investigated as a code or test bug. The investigation file documents the root cause and why the failure is acceptable; it carries no fix instructions.

## Attribution Values (TEST_FAILURE only)

| Value | Meaning |
|-------|---------|
| CODE_BUG | Implementation has a bug; test is correct |
| TEST_BUG | Test itself is wrong (assertion, mock, import) |

Code-investigator may reclassify test-runner's preliminary attribution after independent verification.

## Guarantees

- Every finding backed by tool output (Read, Grep, Bash evidence)
- Self-criticism protocol runs before every verdict
- Progressive depth: starts at Minimum Depth, deepens only when confidence is LOW
- LOW confidence never returned to orchestrator — agent deepens or reframes as LEVEL_4
- LEVEL_4 always reached via Depth 3 — never assigned without exhausting all depths
- LEVEL_3 requires at least 2 genuinely valid approaches with distinct tradeoffs
- `CANNOT_REPRODUCE` (STANDALONE_BUG only) is returned at HIGH confidence when the oracle manifests no defect and no cause surfaces after exhausting depth — a cause is never fabricated to avoid it, and it is never returned when a confirmed-RED reproduction signal is present
- `ACCEPTED_FAILURE` (TEST_FAILURE only) is returned only after independent verification rules out both CODE_BUG and TEST_BUG; it carries no fix instructions, and the decision to skip the test rests with the user
- Test-runner attribution independently verified — never accepted without reading both test and implementation
- Investigation file written with YAML frontmatter to the specified output path
- Each investigation attempt produces its own file at the path the orchestrator supplies (filename pattern `phase-N-{code|test}-investigation-{attempt}.md`, or `<DD-MM-YYYY>-HH-MM-investigation.md` for a STANDALONE_BUG investigation); the file's frontmatter reflects that attempt's verdict
- Normalizes the target file to HEAD state before writing — uncommitted content from a crashed prior dispatch is discarded so the re-dispatched attempt produces a clean result
- Creates parent directories if they don't exist (per create-folder skill)
- Resolution mode verifies investigation file exists before appending
- Resolution mode returns INSUFFICIENT (with `Commit: none`) if user input can't be translated to fixes
- Never modifies source code or test code
- Never asks the user directly — all communication through orchestrator
- Commits **only** its own investigation file — path-scoped, via the `commit-to-git` skill with `Agent: code-investigator`, after the file is written/appended and before returning. Subject form in investigation mode: `investigate(<slug>): phase <N> level-<K>` (or `accepted` for ACCEPTED_FAILURE) for the phase-based triggers; `investigate(<slug>): standalone level-<K>` (or `cannot-reproduce` for CANNOT_REPRODUCE) for STANDALONE_BUG. In resolution mode: `investigate(<slug>): phase <N> resolution-level-<K>`. Never stages or commits implementation code, test code, other agents' artifacts, `ROADMAP.md`, or anything under `.project/product/`
- The return message contains a `Commit:` field on every invocation so the orchestrator can detect interrupted commits and re-dispatch
