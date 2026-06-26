# Test Runner Guide

## What It Does

Executes the project's tests in a dispatched scope and classifies any failures as likely code bugs or test bugs.

**Key Points:**
- Runs the full project suite in `phase` and `full-suite` modes (catching regressions from earlier phases); runs a targeted subset in `reproduction` and `targeted` modes
- Performs preliminary fault attribution for each failure (CODE_BUG / TEST_BUG / UNCLEAR)
- Writes structured results to a persistent file that accumulates Run sections across fix attempts
- Commits the results file path-scoped (worktree-side) before returning, so the audit trail survives `git merge --no-ff` at `/accept-feature`
- Read-only with respect to implementation and test code

## Modes

test-runner runs in one of four modes, selected by a required `Mode:` field:

| Mode | Used by | Tests run |
|------|---------|-----------|
| `phase` | feature pipeline, per-phase | the full project suite |
| `reproduction` | bugfix flow, reproduction run | the reproduction test file(s) named in the test report |
| `full-suite` | bugfix flow, final-phase gate / regression run | the full project suite |
| `targeted` | bugfix flow, intermediate fix phases | the specific test files named in the dispatch |

## When It's Used

In the feature pipeline the orchestrator invokes test-runner (`Mode: phase`) after test files pass code-reviewer's TEST_REVIEW. It sits in the testing pipeline:

```
developer (test-writer) → code-reviewer (TEST_REVIEW) → test-runner → code-investigator (if failures)
```

The bugfix flow calls the same agent in its `reproduction`, `targeted`, and `full-suite` modes. Test-runner is the only agent in the system that actually executes tests.

## How It Works

1. Reads the dispatched mode file to determine this run's scope, test command, and spec-of-record source
2. Runs the project's test command (e.g., `npm run test`) against that scope
3. Parses the output for pass/fail/skip counts and error details
4. For each failure, reads the test file, its spec-of-record (the BDD scenario when one exists, otherwise the bug report's Expected Behavior for a bugfix reproduction test), and the implementation to classify the cause
5. Normalizes the results file to HEAD state (discards any uncommitted Run sections from a crashed prior attempt), then writes/appends the new Run section to the dispatched output path
6. Commits the results file path-scoped via the `commit-to-git` skill
7. Returns a PASS/FAIL summary with a `Commit:` field (hash, `skipped`, or `failed`) to the orchestrator

## Understanding Fault Attribution

Attribution is **preliminary** — code-investigator verifies every classification:

| Attribution | What It Means | What Happens Next |
|-------------|---------------|-------------------|
| CODE_BUG | Test is correct, implementation has a bug | Code-investigator confirms → developer fixes code |
| TEST_BUG | Test itself is wrong (bad assertion, mock, import) | Code-investigator confirms → developer fixes test |
| UNCLEAR | Evidence is ambiguous | Code-investigator resolves or escalates |

Each failure is judged against its **spec-of-record** — the BDD `.feature` scenario for a feature test, or the bug report's Expected Behavior for a bugfix reproduction test that has no `.feature`.

## Results File

Results accumulate at the dispatched output path (e.g. `execution/test-results/phase-N-results.md` for a feature phase). Each invocation appends a new "Run" section, creating a chronological record. This file is read by code-investigator, quality-analyst, and state-manager. Each Run section lands in its own commit attributed to `Agent: test-runner`, so `git log` mirrors the file's audit trail.

## Interrupted-Commit Recovery

If test-runner's dispatch ends without a `Commit:` field (process killed, max-turns hit, hook-blocked stop), the orchestrator re-dispatches the same invocation. test-runner normalizes the results file to HEAD before writing — previously-committed Runs survive untouched; only the crashed attempt's uncommitted Run section is discarded — and then writes the same Run fresh and commits. No audit data is lost, because the discarded Run was never committed.

## Limitations

- Attribution is preliminary — not the final word on fault classification
- Runs tests once per invocation — the orchestrator controls retries
- Cannot diagnose environmental issues (Docker, database state, network)
- Cannot modify code to fix issues it discovers
- Bash usage is limited to running the test command, directory creation, output-path registration, normalizing the results file before write, and committing the results file via `commit-to-git`

## Related Files

- Agent definition: `.claude/agents/test-runner/test-runner.md`
- Mode files: `.claude/agents/test-runner/modes/` (`phase.md`, `reproduction.md`, `full-suite.md`, `targeted.md`)
- Attribution guide: `.claude/agents/test-runner/essentials/attribution-guide.md`
- Results format: `.claude/agents/test-runner/formats/results-format.md`
- Interface contract: `.claude/agents/interface-contracts/test-runner.contract.md`
