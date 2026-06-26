# Investigation Mode

## Workflow

### Step 1: Parse Input

Extract from the orchestrator's prompt:
- `Mode`: must be `investigation`
- `Trigger`: TEST_FAILURE or CODE_REVIEW_FAILURE
- `Cycle`: feature name (used in the investigation file's frontmatter `feature` field)
- `Phase`: phase number and name
- `Cycle Path`: base path for feature artifacts
- `Investigation Output Path`: where to write findings
- `Investigation Attempt`: attempt number (1+)
- `Minimum Depth`: starting depth (0 unless orchestrator overrides)
- `Test Results Path`: path to test-runner results (TEST_FAILURE only)
- `Code Review Path`: path to code-reviewer report (CODE_REVIEW_FAILURE only)
- `Files Involved`: modified/created files from developer
- `Manifest Path`: path to execution manifest
- `Plan Path`: path to implementation plan

### STANDALONE_BUG branch

`STANDALONE_BUG` runs without phase context — no `Phase`, `Plan Path`, or `Manifest Path`. It carries `Bug Report`, an `Investigation Output Path`, and either reproduction artifacts (behavioral) or `Failing Commands` (tool-oracle). It reuses the same engine — Step 2 progressive depth, Step 3 hypothesis/disconfirmation, Step 4 severity, Step 5 related-failure grouping, Step 6 write, Step 7 commit, Step 8 return — with these differences:

1. **Input (Step 1).** Parse `Bug Report`, `Investigation Output Path`, `Investigation Attempt`, `Minimum Depth`, and — when present — `Reproduction Test Report` + `Reproduction Results` (behavioral) or `Failing Commands` (tool-oracle). Register the output path as usual: `echo "[Investigation Output Path]" > /tmp/.claude-agent-output-target`.
2. **Read the bug report first.** It is this flow's specification — `## Symptom`, `## Reproduction`, `## Expected Behavior` / `## Actual Behavior`, `## Affected Area`, and any `## Attached Output` ground the investigation.
3. **Produce the failing signal in your own context, then classify the outcome.**
   - Tool-oracle: run each `Failing Commands` line via Bash and read the full error output (the orchestrator never sees it).
   - Behavioral: when the reproduction artifacts are attached, read them for the confirmed-RED test and its failure detail; when running investigate-first (no artifacts), work from the bug report plus its `## Attached Output` to establish the deterministic conditions.

   A `STANDALONE_BUG` investigation resolves to one of three terminal outcomes; the engine (Steps 2–5) runs the same way regardless:
   - **A defect is found** → classify severity LEVEL_1–LEVEL_4. If the defect's true scenario class differs from the bug report's, keep the verdict and add `Scenario-Reclassification: <correct-scenario>` to the return so the orchestrator re-routes the established cause to the correct path.
   - **No defect, no cause** → conclude `CANNOT_REPRODUCE` (HIGH confidence; `target: n/a`). Document each command run and its clean result.
   - **Reproduce-first** → when a confirmed-RED `Reproduction Results` file is attached, `CANNOT_REPRODUCE` does not apply; investigate the confirmed failure to a severity level.
4. **Context loading (Step 2).** Depths 2–3 reference the manifest / plan / SRS-SDD, which do not exist for a standalone bug — substitute the bug report, the involved source files (from `## Affected Area` and your own tracing), and prior investigation files in the same cycle. Deepen only when confidence is LOW, exactly as for the other triggers.
5. **Output (Step 6).** Title the file `# Investigation — <bug summary>` and set frontmatter `phase: n/a`. For a severity verdict, add one scenario section: `### Deterministic reproduction conditions` (behavioral) or `### Diagnosed error clusters` (tool-oracle); the rest of the body (Root Cause / Evidence / Fix Instructions / Patterns / Verification) follows the standard format for the verdict's level. For a `CANNOT_REPRODUCE` verdict, use the CANNOT_REPRODUCE format below (no Fix Instructions — there is nothing to fix).
6. **Return flags (Step 8).** When the scenario class in the bug report is wrong (but a cause was still found), add `Scenario-Reclassification: <correct-scenario>`. When the error clusters are independent and large, add `Fan-Out-Recommended: true` and sketch each cluster under `### Diagnosed error clusters` so the orchestrator can dispatch one investigator per cluster. A `CANNOT_REPRODUCE` verdict uses its own return template (Step 8) and never carries `Scenario-Reclassification` or `Fan-Out-Recommended`.

### Step 2: Load Context (Progressive)

**Depth 0 — Always load:**
1. The trigger file (test results or code review report)
2. All files listed in "Files Involved"
3. Test files associated with implementation files (TEST_FAILURE only)

**Depth 1 — Load if LOW confidence at Depth 0:**
4. One-hop dependencies: files imported by or importing the involved files (use Grep to trace imports)
5. Related test files not in the initial list

**Depth 2 — Load if LOW confidence at Depth 1:**
6. Manifest file — prior phase summaries and artifacts
7. BDD specs (Grep for `.feature` or `bdd` files under feature path)

**Depth 3 — Load if LOW confidence at Depth 2:**
8. Implementation plan
9. SRS/SDD specs (Glob under `specs/` in feature path)
10. Prior investigation files in the same feature (check for patterns)

If `Minimum Depth` is set, skip depths below it (context already loaded in prior attempt).

### Step 3: Investigate

At each depth level:

1. **Form hypothesis** — Based on evidence loaded so far, what is the most likely root cause?

2. **Seek disconfirming evidence** — What would disprove this hypothesis? Use Read, Grep, Glob, or Bash to check.

3. **Verify test-runner attribution** (TEST_FAILURE only):
   - Read the test file — is the assertion correct? Does the test match the BDD scenario?
   - Read the implementation — does it violate what the test expects?
   - Compare attributions: does test-runner's CODE_BUG/TEST_BUG/UNCLEAR hold up?
   - If reclassifying, document why with evidence from both files

4. **Assess confidence** — HIGH, MEDIUM, or LOW?
   - HIGH/MEDIUM → proceed to Step 4
   - LOW → load next depth level, repeat Step 3

5. **Run self-criticism protocol** (from main definition) before proceeding

### Step 4: Classify Severity

Apply classification rules from the main definition:

- Can a single-file fix resolve it? → LEVEL_1
- Does the fix span multiple files but the approach is clear? → LEVEL_2
- Are there multiple valid approaches with real tradeoffs? → LEVEL_3
- Is automated investigation exhausted with competing hypotheses? → LEVEL_4

For a TEST_FAILURE, one further terminal outcome is available: if independent verification rules out both CODE_BUG and TEST_BUG and the failure is one the team may legitimately accept (intentionally unimplemented behaviour, a deferred decision, or a dropped requirement) → `ACCEPTED_FAILURE`, documenting the root cause and why the failure is acceptable in place of fix instructions.

For LEVEL_3/4, formulate options:
- Each option: name, description, affected files, tradeoff summary
- Recommend one option with rationale (LEVEL_3 only — LEVEL_4 presents hypotheses without recommendation when none is clearly better)

### Step 5: Check for Related Failures

Before writing the investigation file:
1. Are there other failures in the same test run that share a root cause?
2. Group related failures under a single root cause
3. Each grouped failure gets its own entry but references the shared root cause

### Step 6: Write Investigation File

Write to `Investigation Output Path`. Each attempt produces its own file — the orchestrator supplies a per-attempt path matching the pattern `phase-N-{code|test}-investigation-{attempt}.md`, with one `## Attempt [N]` section in the file's body.

**Sub-step 1: Normalize the investigation file to a known state.** Handles the case where a prior dispatch of this same attempt wrote the file but crashed before committing. Run via Bash, substituting the actual Investigation Output Path:

```
if [ -f "<path>" ]; then
  if git ls-files --error-unmatch "<path>" >/dev/null 2>&1; then
    git checkout HEAD -- "<path>"
  else
    rm -f "<path>"
  fi
fi
```

- File doesn't exist → no-op (the common case for a new attempt).
- File tracked at HEAD → `git checkout HEAD -- <path>` discards any uncommitted changes; the previously-committed content of this attempt's file survives unchanged.
- File untracked → `rm` removes the orphan from a crashed prior write of this attempt (it was never in the audit trail).

**Sub-step 2: Directory creation.** Read `.claude/skills/create-folder/SKILL.md` and follow it to create the output directory before writing.

**Sub-step 3: Write the file.** Write the full investigation content fresh — frontmatter plus body in the appropriate format below. `[N]` in the body's `## Attempt [N]` header is the `Investigation Attempt` value from the input.

### Investigation File Format

> For a `STANDALONE_BUG` investigation, substitute the title `# Investigation — <bug summary>` for `# Phase [N] Investigation — [Phase Name]`, set frontmatter `phase: n/a`, and add the scenario section described in the STANDALONE_BUG branch above (`### Deterministic reproduction conditions` for behavioral, `### Diagnosed error clusters` for tool-oracle). All other structure below is unchanged.

**For LEVEL_1 / LEVEL_2:**

```markdown
# Phase [N] Investigation — [Phase Name]

## Attempt [N]
**Trigger:** TEST_FAILURE | CODE_REVIEW_FAILURE
**Depth Reached:** [0-3]
**Confidence:** HIGH | MEDIUM

### Failures Investigated
| # | Source | Test/Finding | Original Attribution | Final Attribution |
|---|--------|--------------|---------------------|-------------------|
| 1 | [test-runner / code-reviewer] | [test name or finding ID] | [CODE_BUG/TEST_BUG/UNCLEAR or N/A] | [CODE_BUG/TEST_BUG] |

### Root Cause Analysis
**Root Cause:** [concise statement]
**Evidence:**
- [tool]: [file:line] — [what it shows]
- [tool]: [file:line] — [what it shows]

**Disconfirming Evidence Sought:**
- [what was checked and ruled out]

### Fix Instructions
**Severity:** LEVEL_1 | LEVEL_2
**Target:** code | test

| # | File | Line | Action | Detail |
|---|------|------|--------|--------|
| 1 | [path] | [N] | [add/modify/remove] | [exact instruction] |

### Patterns
[Any recurring patterns detected, or "None detected"]

### Verification
- [commands to run after fix to confirm resolution]
```

**For LEVEL_3:**

```markdown
# Phase [N] Investigation — [Phase Name]

## Attempt [N]
**Trigger:** TEST_FAILURE | CODE_REVIEW_FAILURE
**Depth Reached:** [0-3]
**Confidence:** HIGH | MEDIUM

### Failures Investigated
[same table as above]

### Root Cause Analysis
**Root Cause:** [concise statement]
**Evidence:**
- [evidence items]

### Design Decision Required
**Severity:** LEVEL_3

#### Option A: [Name]
**Description:** [what this approach does]
**Affected Files:** [list]
**Tradeoff:** [pro/con]

#### Option B: [Name]
**Description:** [what this approach does]
**Affected Files:** [list]
**Tradeoff:** [pro/con]

**Recommendation:** [Option X] — [rationale]

### Patterns
[patterns or "None detected"]
```

**For LEVEL_4:**

```markdown
# Phase [N] Investigation — [Phase Name]

## Attempt [N]
**Trigger:** TEST_FAILURE | CODE_REVIEW_FAILURE
**Depth Reached:** 3
**Confidence:** HIGH (verdict: human judgment required)

### Failures Investigated
[same table as above]

### Investigation Exhausted
**Summary:** [what was investigated and why disambiguation failed]

**Depths Traversed:**
- Depth 0: [what was checked, what was found]
- Depth 1: [what was checked, what was found]
- Depth 2: [what was checked, what was found]
- Depth 3: [what was checked, what was found]

### Competing Hypotheses

#### Hypothesis A: [Name]
**Supporting Evidence:**
- [evidence items]
**Weaknesses:** [why this isn't conclusive]

#### Hypothesis B: [Name]
**Supporting Evidence:**
- [evidence items]
**Weaknesses:** [why this isn't conclusive]

### What Would Resolve This
[What information or decision from the user would disambiguate]

### Patterns
[patterns or "None detected"]
```

**For CANNOT_REPRODUCE (STANDALONE_BUG only):**

```markdown
# Investigation — <bug summary>

## Attempt [N]
**Trigger:** STANDALONE_BUG
**Depth Reached:** [0-3]
**Confidence:** HIGH (verdict: the reported failure does not reproduce)

### Reproduction Attempted
**Outcome:** Could not reproduce the reported failure in a clean worktree at `<commit>`.

**What was run:**
- [tool-oracle: each `Failing Commands` line and its exit code; behavioral: the conditions exercised]

**Evidence:**
- [tool]: [file:line or command] — [the clean result that shows no defect]

**Depths Traversed:**
- Depth 0–[N]: [what was checked; why no cause surfaced]

### Why This Is Not a Defect
[Concise statement: the oracle passes and no underlying cause was found after exhausting depth. Note plausible external explanations — environment drift, already fixed since reported, or a mis-described symptom — without asserting one as fact.]

### Patterns
[patterns or "None detected"]
```

**For ACCEPTED_FAILURE (TEST_FAILURE only):**

```markdown
# Phase [N] Investigation — [Phase Name]

## Attempt [N]
**Trigger:** TEST_FAILURE
**Depth Reached:** [0-3]
**Confidence:** HIGH (verdict: the failure is acceptable; user confirmation required)

### Failures Investigated
[same table as above]

### Root Cause Analysis
**Root Cause:** [why the test fails]
**Evidence:**
- [tool]: [file:line] — [what it shows]

**Disconfirming Evidence Sought:**
- [what was checked to rule out CODE_BUG and TEST_BUG]

### Why This Failure Is Acceptable
[Concise statement: the failure is not a code or test defect — it exercises intentionally-unimplemented behaviour, a deferred decision, or a dropped requirement. State the suggested inline reason for the `test.skip` annotation the developer adds on user confirmation.]

### Patterns
[patterns or "None detected"]
```

### Step 7: Commit Investigation File

After the investigation file exists (satisfying the completion gate) and before returning, Read `.claude/skills/commit-to-git/SKILL.md` and follow it to commit the investigation file path-scoped. Pass:

- `Agent: code-investigator`
- `Path:` the exact Investigation Output Path written in Step 6
- `Subject:`
  - phase-based triggers (`TEST_FAILURE`, `CODE_REVIEW_FAILURE`): `investigate(<slug>): phase <N> level-<K>` where `<K>` is the verdict's numeric level (1–4), or `investigate(<slug>): phase <N> accepted` for an ACCEPTED_FAILURE verdict.
  - `STANDALONE_BUG` (no phase in the input): `investigate(<slug>): standalone level-<K>` for a severity verdict, or `investigate(<slug>): standalone cannot-reproduce` for a `CANNOT_REPRODUCE` verdict.

Where `<slug>` is the basename of the feature directory derived from `Investigation Output Path` (the directory two levels up from `code-investigations/` — i.e., `.project/cycles/<slug>/execution/code-investigations/` → `<slug>`); `<N>` is the phase number from the input (phase-based triggers only).

Commit nothing else. One commit per invocation. Capture the resulting short hash for Step 8; if the commit produced no change (the normalized file matched HEAD and the fresh write reproduced it byte-for-byte), record `skipped`. If the commit fails (lock contention, hook rejection, transient error), record `failed` and surface it in the return — never report a success hash for a commit that did not happen.

A failed commit must never block the return from happening; the investigation file is already written and the SubagentStop hook is satisfied.

### Step 8: Return Structured Output

Return the structured message below to the orchestrator. The template depends on the verdict from Step 4. `Commit:` semantics are documented in `code-investigator.md` Output Format.

**LEVEL_1 / LEVEL_2:**
```
Verdict: LEVEL_1 | LEVEL_2
Confidence: HIGH | MEDIUM
Target: code | test (TEST_FAILURE trigger only)
Investigation File: [Investigation Output Path]
Commit: [short-hash | skipped | failed]
```

**LEVEL_3:**
```
Verdict: LEVEL_3
Confidence: HIGH | MEDIUM
Investigation File: [Investigation Output Path]
Commit: [short-hash | skipped | failed]
Root Cause: [summary]
Options: [numbered list with tradeoffs]
Recommendation: [which option and why]
```

**LEVEL_4:**
```
Verdict: LEVEL_4
Confidence: HIGH
Investigation File: [Investigation Output Path]
Commit: [short-hash | skipped | failed]
Investigation Exhausted: [what was tried and why it's inconclusive]
Competing Hypotheses: [numbered list with evidence for/against]
What Would Resolve This: [what information or decision is needed]
```

**ACCEPTED_FAILURE:**
```
Verdict: ACCEPTED_FAILURE
Investigation File: [Investigation Output Path]
Commit: [short-hash | skipped | failed]
Root Cause: [why this failure is expected/acceptable]
```

**CANNOT_REPRODUCE (STANDALONE_BUG only):**
```
Verdict: CANNOT_REPRODUCE
Confidence: HIGH
Investigation File: [Investigation Output Path]
Commit: [short-hash | skipped | failed]
Summary: [one line — the reported failure does not reproduce in a clean worktree at <commit>]
```

For a `STANDALONE_BUG` severity verdict (LEVEL_1–LEVEL_4), append `Scenario-Reclassification: <build | lint | type | crash | logic>` when the reported scenario class was wrong, and `Fan-Out-Recommended: true` when independent large error clusters warrant additional investigators. These flags never appear on a `CANNOT_REPRODUCE` return.
