# test-runner Interface Contract

## Input

test-runner selects its test scope from a required `Mode:` field. Every mode also takes the common fields below; the per-mode required inputs differ.

**Common fields (all modes):**
```
Mode: phase | reproduction | full-suite | targeted
Cycle: [cycle-slug]
Cycle Path: [.project/cycles/<slug>/]
Phase: [N]: [phase-name]
Results Output Path: [path to write results file]
```

**Per-mode inputs:**

| `Mode:` | Tests run | Additional required input | Reports |
|---|---|---|---|
| `phase` | the full project suite | none | `Implementation Report` / `Test Report` **optional** — attribution context only; absent or `none` is valid |
| `reproduction` | the test files in `Test Report`'s `## Files Modified` | `Test Report` | `Implementation Report` not used |
| `full-suite` | the full project suite | none | none |
| `targeted` | the test files named in `Files:` | `Files:` (semicolon- or newline-separated test paths) | none |

`phase` runs the full suite regardless of whether reports are supplied — the reports, when present, are read only to inform attribution; they never narrow the run.

### The `Phase: 0:` form

A pre-plan bugfix run — the reproduction run precedes any implementation plan — names the phase with a numeric prefix and a descriptive sub-step suffix:

```
Phase: 0: bugfix-reproduce
```

The results frontmatter `phase:` field and the commit subject's `phase <N>` token take the **numeric prefix only** (`0`); the descriptive sub-step name appears only in the results file's human-readable header. Downstream consumers parse `phase:` exactly as for any other run.

### Example Invocations

**`phase` — feature pipeline per-phase run:**
```
Mode: phase
Cycle: 15-03-2026-notification-system
Cycle Path: .project/cycles/15-03-2026-notification-system/
Phase: 2: Implement notification delivery service
Implementation Report: .project/cycles/15-03-2026-notification-system/execution/developer-reports/phase-2-implementation-report.md
Test Report: .project/cycles/15-03-2026-notification-system/execution/developer-reports/phase-2-test-report.md
Results Output Path: .project/cycles/15-03-2026-notification-system/execution/test-results/phase-2-results.md
```

**`reproduction` — bugfix reproduction run (expects RED):**
```
Mode: reproduction
Cycle: 22-05-2026-fix-session-drop
Cycle Path: .project/cycles/22-05-2026-fix-session-drop/
Phase: 0: bugfix-reproduce
Test Report: .project/cycles/22-05-2026-fix-session-drop/execution/developer-reports/reproduction-test-report.md
Results Output Path: .project/cycles/22-05-2026-fix-session-drop/execution/test-results/reproduction-results.md
```

**`full-suite` — bugfix final-phase gate:**
```
Mode: full-suite
Cycle: 22-05-2026-fix-session-drop
Cycle Path: .project/cycles/22-05-2026-fix-session-drop/
Phase: 3: Persist refresh token
Results Output Path: .project/cycles/22-05-2026-fix-session-drop/execution/test-results/phase-3-results.md
```

**`targeted` — bugfix intermediate fix phase:**
```
Mode: targeted
Cycle: 22-05-2026-fix-session-drop
Cycle Path: .project/cycles/22-05-2026-fix-session-drop/
Phase: 2: Fix token refresh guard
Files: src/auth/session.service.spec.ts; src/auth/refresh.guard.spec.ts
Results Output Path: .project/cycles/22-05-2026-fix-session-drop/execution/test-results/phase-2-results.md
```

## Output

The test-runner writes a results file to `Results Output Path`, commits it path-scoped, and returns a structured message. The results file is the source of truth for downstream agents (code-investigator, quality-analyst); the message provides routing data — including the commit signal — for the orchestrator.

### Results File Format

Every results file starts with YAML frontmatter:

```yaml
---
overall: PASS | FAIL | BLOCKED
phase: [N]
cycle: <slug>
pass-count: [N]
fail-count: [N]
---
```

The body documents per-test results and failure details with attribution (run header, summary table, failures table with evidence). Each test-runner invocation appends a new Run section to the file, producing a chronological audit trail across fix attempts.

### Message to Orchestrator

**PASS:**
```
Overall: PASS
Commit: [short-hash | skipped | failed]
Results: [path]
```

**FAIL:**
```
Overall: FAIL
Commit: [short-hash | skipped | failed]
Results: [path]
```

**BLOCKED** — the test command itself failed to execute (not test failures; the command errored before producing test output). The agent still writes a minimal results file documenting the block, so `Commit:` carries a real value.
```
Overall: BLOCKED
Commit: [short-hash | skipped | failed]
Results: [path]
Reason: [error message from the failed test command]
```

`Commit:` semantics:

| Value | Meaning |
|---|---|
| `<short-hash>` | The results file was written and successfully committed path-scoped to the worktree. |
| `skipped` | The write produced no diff against HEAD (a re-dispatch reproduced byte-identical content). No commit was made. |
| `failed` | The commit step failed (lock contention, hook rejection, transient error). The results file exists on disk; manual investigation required. |
| `none` | Not produced by this agent. The Completion Gate guarantees a results file exists on every successful return, so the commit step always has something to act on. Documented for pipeline-convention completeness. |

## Recovery

If the dispatch returns without a `Commit:` field (process killed mid-run, max-turns hit, hook-blocked stop, no return at all), re-dispatch the same invocation. test-runner guarantees an idempotent write: a re-dispatched attempt produces the same Run section the crashed attempt would have committed, regardless of any partial state left by the prior attempt. Do NOT re-dispatch on `Commit: failed` — the results file is written and a re-dispatch would loop on the same failure.

## Attribution Values

| Value | Meaning | Orchestrator Action |
|-------|---------|---------------------|
| CODE_BUG | Implementation has a bug; test appears correct | Invoke code-investigator to verify → developer fixes implementation |
| TEST_BUG | Test itself appears wrong | Invoke code-investigator to verify → developer (test-writer) fixes test |
| UNCLEAR | Cannot determine with confidence | Invoke code-investigator to resolve ambiguity |

Attribution is preliminary. Code-investigator may reclassify.

## Guarantees

- Runs actual tests via Bash and reports actual output — never fabricates results
- Every failure includes attribution with evidence
- Results file written with YAML frontmatter to the specified output path
- Appends to existing results file (new run section, frontmatter updated) if file exists from a prior committed run
- Normalizes the results file to HEAD state before writing — uncommitted Run sections from a crashed prior attempt are discarded so the re-dispatched attempt produces a clean append
- Creates `execution/test-results/` directory if it doesn't exist (per create-folder skill)
- Never modifies implementation code or test code
- Never re-runs tests within a single invocation
- Never asks the user directly — all communication goes through orchestrator
- Commits **only** its own results file — path-scoped, via the `commit-to-git` skill with `Agent: test-runner`, after the results file is written and before returning. Subject form: `test(<slug>): phase <N> results`. Never stages or commits implementation code, test code, other agents' artifacts, `ROADMAP.md`, or anything under `.project/product/`. This is the sole exception to its otherwise read-only-with-respect-to-code stance
- The return message contains `Overall`, `Commit`, and `Results` — every invocation reports a `Commit:` value so the orchestrator can detect interrupted commits and re-dispatch
