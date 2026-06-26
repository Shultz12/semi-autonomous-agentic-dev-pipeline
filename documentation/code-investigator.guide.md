# Code Investigator Guide

## What It Does

Investigates the root causes of code and test failures, going beyond surface-level error messages to find the actual source of problems.

**Key Points:**
- Uses progressive depth analysis (4 levels) — starts with the failing code, widens scope only when needed
- Classifies every finding into 4 severity levels, from simple local fixes to decisions requiring your input
- Independently verifies test-runner's fault attribution (CODE_BUG vs TEST_BUG)
- Produces structured investigation files with exact fix instructions or options for you to choose from
- Records your decisions on escalated issues so developers can implement them

## When It's Used

The orchestrator invokes code-investigator after test-runner reports failures or when code-reviewer findings need deeper root cause analysis. It sits in the failure resolution pipeline:

```
test-runner (FAIL) → code-investigator → developer (fixes)
                                       ↘ user (Level 3/4 decisions)
                                         ↘ code-investigator (resolution) → developer
```

Code-investigator is also invoked after code-reviewer findings when the orchestrator determines deeper analysis is needed beyond what code-reviewer provides.

## How Progressive Depth Works

Instead of loading everything upfront, code-investigator widens its search incrementally:

| Depth | What's Loaded | When Reached |
|-------|---------------|-------------|
| 0 | Failing files + test files | Always (starting point) |
| 1 | One-hop dependencies (imports/importers) | Depth 0 evidence is inconclusive |
| 2 | Manifest, BDD specs, prior phase context | Depth 1 evidence is inconclusive |
| 3 | Implementation plan, SRS/SDD, prior investigations | Depth 2 evidence is inconclusive |

Most failures resolve at Depth 0 or 1. Reaching Depth 3 is rare and signals genuine complexity.

## Understanding Severity Levels

| Level | What It Means | What Happens |
|-------|---------------|-------------|
| LEVEL_1 — Local | Simple fix in one file | Developer gets exact fix instructions |
| LEVEL_2 — Cross-cutting | Fix spans multiple files but approach is clear | Developer gets multi-file instructions with context |
| LEVEL_3 — Design decision | Multiple valid approaches exist | You see options with tradeoffs and a recommendation |
| LEVEL_4 — Human judgment | Investigation exhausted, can't disambiguate | You see competing hypotheses to evaluate |

**Level 3** means there are genuinely different valid approaches — not "one obvious fix plus a contrived alternative." You'll see each option with its tradeoffs and a recommendation.

**Level 4** means the investigator exhausted all depth levels (Depth 0 through 3) and still can't determine the root cause. You'll see the competing hypotheses with their evidence so you can apply domain knowledge the investigator doesn't have.

**Accepted failures (test failures only).** Sometimes a failing test isn't signalling a real defect — it may exercise behaviour that's intentionally unimplemented or assert a requirement that's been dropped. When the investigator rules out both a code bug and a test bug, it can classify the failure as *accepted* and present the root cause for your confirmation. If you confirm, the test is marked skipped with an inline reason rather than fixed; if you reject, it's re-investigated as a code or test bug.

## Your Role in Level 3/4 Findings

When the orchestrator presents a Level 3 or Level 4 finding:

1. **Read the investigation file** — it contains the full analysis with evidence
2. **Make your decision** — choose an option (Level 3) or evaluate hypotheses (Level 4)
3. **Tell the orchestrator** — your decision gets sent to code-investigator in resolution mode
4. **Code-investigator translates** — turns your decision into concrete fix instructions for the developer

You don't need to specify file paths or line numbers — just the direction. The investigator handles the technical details.

## Investigation Files

Investigation files accumulate at `execution/code-investigations/` within the feature directory. Each attempt produces its own file, named by phase, type, and attempt:

```
execution/code-investigations/
├── phase-2-test-investigation-1.md
├── phase-2-test-investigation-2.md    (re-investigation after fix attempt)
└── phase-3-code-investigation-1.md
```

These files form a permanent record of what was investigated, what was found, and how it was resolved. The investigator commits each file path-scoped to the worktree before returning, so the audit trail survives the merge to main.

The return message carries a `Commit:` field — a short hash on success, `skipped` when a re-dispatch produced byte-identical content, `failed` when the commit step itself errored, or `none` when no write occurred (resolution mode INSUFFICIENT path only).

## Interrupted-Commit Recovery

If a code-investigator dispatch ends without returning (process killed, max-turns hit, hook-blocked stop) or returns without a `Commit:` field, the orchestrator re-dispatches the same invocation. Before each write, the investigator normalizes the target file to a known state — restoring previously-committed content if the file is tracked, or removing the orphan from a crashed prior write if it is untracked. The re-dispatched attempt produces the same investigation (one file per attempt) or re-appends the resolution, and commits cleanly. The orchestrator never re-dispatches on `Commit: failed`, because the file is already written and a re-dispatch would loop on the same failure.

## Limitations

- Cannot fix code — investigates and prescribes only
- Cannot diagnose environmental issues (Docker, database state, network)
- Level 4 findings require your input — the investigator presents what it found, you decide
- Pattern detection is heuristic — based on observed repetition within the feature, not statistical analysis
- Progressive depth adds latency for deep investigations (Depth 2-3)
- Bash is used for runtime diagnostics, directory creation, output-path registration, normalizing the investigation file before write, and committing the file — never to modify source or test code

## Related Files

- Agent definition: `.claude/agents/code-investigator/code-investigator.md`
- Investigation mode: `.claude/agents/code-investigator/modes/investigate.md`
- Resolution mode: `.claude/agents/code-investigator/modes/resolution.md`
- Interface contract: `.claude/agents/interface-contracts/code-investigator.contract.md`
