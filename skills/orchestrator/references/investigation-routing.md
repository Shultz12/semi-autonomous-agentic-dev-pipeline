# Investigation Verdict Routing

Determines orchestrator action based on code-investigator's verdict. The orchestrator reads the verdict and confidence from code-investigator's return, looks it up here, and follows the instructions. The orchestrator never reads the investigation file content — it routes paths.

## LEVEL_1 (local fix)

1. Route investigation file path to developer:
   ```
   Developer Type: [same as phase, or test if Target is test]
   ...standard fix mode fields...

   Investigation File: [investigation file path]
   Code Review Path: [code-reviewer's Review File path — include when trigger is CODE_REVIEW_FAILURE so developer can address non-investigated findings alongside prescribed fixes]

   Instruction: Read the investigation file, apply the prescribed fixes, then re-run verification. If a Code Review Path is provided, also address any remaining findings not covered by the investigation.
   ```
2. After fix: code-reviewer re-reviews
3. If confidence is MEDIUM and fix fails: re-invoke code-investigator with Minimum Depth increased by 1 (do not count as another developer fix attempt)

## LEVEL_2 (cross-phase fix)

1. Route investigation file path to developer (same dispatch as LEVEL_1, including Code Review Path when applicable)
2. Warn developer in dispatch: "Fix touches prior-phase files — review blast radius"
3. After fix: code-reviewer re-reviews ALL modified files (not just current phase files)
4. If confidence is MEDIUM and fix fails: re-invoke code-investigator with Minimum Depth increased by 1 (do not count as another developer fix attempt)

## LEVEL_3 (plan deviation)

1. Pause execution
2. Present to user (from code-investigator output — Root Cause + Options table):
   ```
   ESCALATION — Phase [N]: [phase name]
   Reason: Plan deviation detected — user decision required

   [Root Cause from code-investigator output]

   [Options table from code-investigator output]
   [Recommendation from code-investigator output]

   What I need from you: Choose an option or provide an alternative approach.
   ```
3. After user decides, invoke code-investigator in resolution mode:
   ```
   Mode: resolution
   Phase: [N]: [phase-name]
   Investigation File Path: [path to investigation file]
   Level: LEVEL_3
   Resolution: [user's chosen option]
   Rationale: [user's reasoning, or "Not provided"]
   ```
4. If resolution succeeds:
   - Spawn plan-architect in update mode with the resolution context
   - Extract from plan-architect message: `Status`, `Routing`, `Change-Level`, `Target-Phase`, `Changelog`
   - If `Status: SUCCESS`:
     - Spawn plan-auditor on updated plan (phase-only on `Target-Phase`)
     - If VALID: reset all phase counters, re-spawn developer with `Reset To Commit: [phase_start_commit]` and `Plan Revised: true` for `Target-Phase` → Step A
     - If INVALID: escalate to user
   - If `Status: ERROR`: escalate to user
5. If resolution returns INSUFFICIENT: re-present to user with what's missing

## LEVEL_4 (user intervention)

1. Pause execution
2. Present to user (from code-investigator output — Investigation Exhausted + Competing Hypotheses + What Would Resolve This):
   ```
   ESCALATION — Phase [N]: [phase name]
   Reason: Architectural issue detected — user intervention required

   [Investigation Exhausted from code-investigator output]

   [Competing Hypotheses table from code-investigator output]

   [What Would Resolve This from code-investigator output]

   What I need from you: Evaluate the hypotheses and provide direction.
   ```
3. After user decides, invoke code-investigator in resolution mode:
   ```
   Mode: resolution
   Phase: [N]: [phase-name]
   Investigation File Path: [path to investigation file]
   Level: LEVEL_4
   Resolution: [user's decision text]
   Rationale: [user's reasoning, or "Not provided"]
   ```
4. Route based on resolution output — may require plan update (follow LEVEL_3 step 4), direct fix (follow LEVEL_1/2), or further investigation

## ACCEPTED_FAILURE (test only)

1. Present to user:
   ```
   Code-investigator classified this test failure as an accepted failure:
   [Root Cause from code-investigator output]

   Confirm skipping this test? [Yes / No]
   ```
2. If confirmed: route to developer (test-writer) to mark test as `test.skip` with inline reason, then re-run test-runner to confirm remaining tests pass
3. If rejected: re-invoke code-investigator to investigate as CODE_BUG or TEST_BUG (reset Investigation Attempt to 1)

## Test Failure Fix Routing (LEVEL_1 / LEVEL_2)

When code-investigator returns LEVEL_1 or LEVEL_2 for a TEST_FAILURE trigger, the Target field determines which developer persona receives the fix.

### Target: code (CODE_BUG confirmed)

```
code_bug_fixes += 1
if code_bug_fixes > 2 → ESCALATE ("Test-detected code bug unresolvable in Phase [N]")
```

1. Re-spawn developer (implementation persona) with investigation file
2. After fix: spawn code-reviewer (PHASE_REVIEW, writes new attempt file to code-reviews/)
3. If code-review PASS: re-run test-runner
4. If code-review FAIL: route through diagnostic-routing.md as normal
5. If test-runner PASS: proceed to Step I
6. If test-runner FAIL: re-invoke code-investigator (Investigation Attempt += 1)

### Target: test (TEST_BUG confirmed)

```
test_bug_fixes += 1
if test_bug_fixes > 2 → ESCALATE ("Test-detected test bug unresolvable in Phase [N]")
```

1. Re-spawn developer (test-writer) with investigation file
2. After fix: spawn code-reviewer (TEST_REVIEW, writes new attempt file to code-reviews/)
3. If code-review PASS: re-run test-runner
4. If code-review FAIL: route through diagnostic-routing.md § TEST_REVIEW as normal
5. If test-runner PASS: proceed to Step I
6. If test-runner FAIL: re-invoke code-investigator (Investigation Attempt += 1)

### MEDIUM Confidence Re-investigation

If the developer's fix (based on a MEDIUM confidence investigation) fails test-runner again:
- Do NOT count as another developer fix attempt
- Re-invoke code-investigator with Minimum Depth increased by 1
- This gives code-investigator a chance to load more context and refine the diagnosis
