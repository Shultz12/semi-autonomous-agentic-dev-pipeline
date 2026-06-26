# Test Mode

Behavioral testing workflow. Follow these phases sequentially.

## Phase 1: Target & Context

### If agent name provided in args

(e.g., `/agent-architect test code-reviewer`)

1. Glob for the agent in `.claude/agents/[name]/` and `.claude/skills/[name]/`
2. If found → proceed to read
3. If not found → report error, show available agents/skills list

### If no agent name provided

1. Glob `.claude/agents/*/` and `.claude/skills/*/`
2. Present list via AskUserQuestion: "Which agent would you like to test?"
3. User selects target

### Context Loading

1. **Read main definition file:**
   - Sub-agent: `.claude/agents/[name]/[name].md`
   - Skill: `.claude/skills/[name]/SKILL.md`

2. **Read ALL supporting files:**
   - Glob `[agent-dir]/**/*.md` for docs, modes, essentials, references
   - Read each file to understand the agent's full behavior

3. **Determine artifact type:**
   - Sub-agent (has `subagent_type` in frontmatter or lives in `.claude/agents/`) → spawnable via Agent tool
   - Skill (has SKILL.md, lives in `.claude/skills/`) → requires subagent to read and execute

4. **Check for existing workspace:**
   - Look for `.claude/agent-evals/[name]/`
   - If exists with `evals/evals.json` → offer to reuse test cases or start fresh
   - If exists with iteration directories → determine next iteration number

## Phase 2: Test Case Design

### Propose Test Cases

Based on the agent's stated responsibilities, propose 2-3 test cases:

```
Based on [agent-name]'s responsibilities, I propose these test cases:

**Test 1: [name]**
- Prompt: "[realistic task prompt]"
- Assertions:
  1. [verifiable behavioral assertion]
  2. [verifiable behavioral assertion]

**Test 2: [name]**
- Prompt: "[realistic task prompt]"
- Assertions:
  1. [verifiable behavioral assertion]
  2. [verifiable behavioral assertion]
```

### Assertion Quality Guidelines

Good assertions test meaningful behavioral outcomes:
- "The agent read the file before proposing changes" (process check)
- "The output contains a validation results section" (format check)
- "The agent did not modify files outside the target directory" (constraint check)
- "The response follows the documented output schema" (contract check)

Avoid weak assertions:
- "The agent produced output" (trivially satisfied)
- "The response is helpful" (not verifiable)

### Refinement

Present test cases in the Agent Summary. Refine collaboratively with the user.

### Save Test Cases

After user approval, save to `.claude/agent-evals/[name]/evals/evals.json`:

```json
{
  "agent_name": "[name]",
  "agent_type": "sub-agent|skill",
  "agent_path": "[path to agent definition]",
  "evals": [
    {
      "id": 1,
      "name": "descriptive-name",
      "prompt": "The task prompt to send to the agent",
      "expected_output": "Human-readable description of what success looks like",
      "expectations": [
        "Verifiable assertion 1",
        "Verifiable assertion 2"
      ]
    }
  ]
}
```

For the evals.json schema, see [../references/eval-schemas.md](../references/eval-schemas.md).

## Phase 3: Execution

### Create Workspace Structure

```
.claude/agent-evals/[name]/
├── evals/
│   └── evals.json
└── iteration-N/
    └── eval-[eval-name]/
        └── with_agent/
            ├── run-1/
            │   ├── outputs/       # Files the agent produced
            │   ├── transcript.md  # Execution transcript
            │   └── timing.json    # Token/duration metrics
            └── eval_metadata.json # Eval prompt and ID
```

### Execute Each Test Case

For each eval in `evals.json`:

1. **Create directory:** `iteration-N/eval-[eval-name]/with_agent/run-1/`

2. **Write eval metadata:**
   ```json
   {
     "eval_id": 1,
     "eval_name": "descriptive-name",
     "prompt": "The task prompt"
   }
   ```
   Save to `iteration-N/eval-[eval-name]/eval_metadata.json`

3. **Spawn the agent:**

   **For sub-agents:**
   ```
   Agent({
     subagent_type: "[agent-type]",
     prompt: "[eval prompt]",
     description: "Test [agent-name]"
   })
   ```

   **For skills:**
   ```
   Agent({
     prompt: "Read the skill at [skill-path] and follow its instructions to complete this task: [eval prompt]. Save all output files to [outputs-dir]/. When done, write a transcript of your execution steps to [transcript-path].",
     description: "Test [agent-name]"
   })
   ```

4. **Capture results:**
   - Save any output files to `run-1/outputs/`
   - Save execution transcript to `run-1/outputs/transcript.md`
   - Write `run-1/timing.json` with duration and token data from the Agent completion notification

5. **Report progress:**
   > "Test 1 of 3 complete: [eval-name]. Proceeding to next test..."

### Error Handling

- If a test fails to execute (agent crashes, timeout): record the error in `run-1/outputs/error.md` and continue with next test
- If the agent lacks Agent tool access: report error and suggest the user grant it, or offer to test via alternative method
- If no tests can execute: abort and explain why

## Phase 4: Grading & Review

### Step 1: Grade Each Run

For each completed run, spawn a behavior-grader:

```
Agent({
  prompt: "You are a behavior grader. Read your instructions at [path-to-behavior-grader.md].

  Grade this agent execution:
  - expectations: [list of assertion strings from evals.json]
  - transcript_path: [path to transcript.md]
  - outputs_dir: [path to outputs/ directory]

  Additional agent-specific criteria:
  - Did the agent follow its stated mandate: [agent mandate]?
  - Did the agent respect its tool restrictions: [allowed tools]?
  - Did the output match the agent's documented format (if any)?

  Write grading results to: [run-dir]/grading.json",
  description: "Grade [agent-name] test"
})
```

The behavior-grader instructions are at `agents/behavior-grader.md` within this skill's directory.

### Step 2: Aggregate Results

Run the benchmark aggregation script:

```bash
python .claude/skills/agent-architect/scripts/aggregate_benchmark.py \
  .claude/agent-evals/[name]/iteration-N/ \
  --skill-name "[name]"
```

This produces `benchmark.json` and `benchmark.md` in the iteration directory.

### Step 3: Analyze Patterns

Spawn the behavior-analyzer:

```
Agent({
  prompt: "You are a behavior analyzer. Read your instructions at [path-to-behavior-analyzer.md].

  Analyze benchmark results and execution transcripts:
  - benchmark_data_path: [path to benchmark.json]
  - agent_path: [path to agent definition]
  - transcript_paths: [list of paths to run-N/outputs/transcript.md files]
  - output_path: [iteration-dir]/notes.json

  Write observations as a JSON array of strings.",
  description: "Analyze [agent-name] results"
})
```

### Step 4: Launch Viewer

Generate the review interface:

```bash
python .claude/skills/agent-architect/scripts/generate_review.py \
  .claude/agent-evals/[name]/iteration-N/ \
  --skill-name "[name]" \
  --benchmark .claude/agent-evals/[name]/iteration-N/benchmark.json \
  --static .claude/agent-evals/[name]/iteration-N/review.html
```

**Platform note:** Always use `--static` flag to generate standalone HTML. This avoids cross-platform issues with the HTTP server.

### Step 5: Present Results

Show a results summary:

```
**Test Results: [agent-name] (Iteration N)**

| Test | Pass Rate | Passed | Failed | Duration |
|------|-----------|--------|--------|----------|
| [name] | X% | N | N | Ns |
| [name] | X% | N | N | Ns |

**Overall:** X% pass rate across N assertions

**Analyzer Notes:**
- [observation 1]
- [observation 2]

Review the detailed results: [path to review.html]
Open it in your browser to leave feedback on individual test outputs.

When you're done reviewing, come back and I'll read your feedback.
```

### Step 6: Collect Feedback

When the user returns:
1. Check for `feedback.json` in the iteration directory
2. If found, read and parse it
3. If not found, ask the user for verbal feedback

## Phase 5: Iteration

### Analyze Failures

Based on grading results and user feedback:
1. Identify which assertions failed and why
2. Identify patterns across failures (e.g., "agent consistently ignores constraint X")
3. Check eval feedback from grader — were any assertions weak?

### Improvement Philosophy

When improving the agent based on test results:

1. **Generalize from specific failures.** If a test case fails because the agent didn't read a file before editing, don't add "always read file X" — add guidance about verifying state before modifying it. The agent will face many different tasks, not just these test cases.

2. **Read the execution transcript, not just the grading output.** The transcript shows where the agent spent time, what tools it used, and where it went wrong. The grading output only shows whether assertions passed. Transcripts reveal root causes; grades reveal symptoms.

3. **Explain the why in your fixes.** When adding or changing an instruction in the agent definition, include the reasoning. "Check file existence before editing (prevents errors when files have been moved or renamed)" is more durable than "ALWAYS check file existence before editing."

4. **Remove what isn't working.** If an instruction causes the agent to waste time on unproductive work (visible in the transcript), consider removing or simplifying it rather than adding more instructions on top.

### Propose Changes

Present specific, actionable changes to the agent definition:

```
Based on the test results, I recommend these changes:

**Agent Definition Changes:**
1. [Specific instruction change] — addresses [failure pattern]
2. [Additional example to add] — helps with [edge case]

**Eval Improvements:**
1. [Assertion to strengthen] — grader noted it was trivially satisfied
2. [New assertion to add] — covers [unchecked behavior]

Would you like me to apply these changes?
```

**STOP & WAIT** — Do not apply changes without user approval.

### Apply & Re-run

After approval:
1. Apply changes to agent definition files (show full file contents for approval first)
2. Update evals.json if eval improvements were approved
3. Re-run tests into `iteration-N+1/`
4. If previous iteration exists, pass `--previous-workspace` to the viewer for comparison
5. Repeat until user is satisfied or no meaningful progress, up to a maximum of 5 iterations
6. If 5 iterations are reached without convergence, present a summary of all iteration results and advise the user to review the agent definition manually

### Completion

When the user is satisfied:

```
**Behavioral testing complete for [agent-name].**

Results summary:
- Iterations: N
- Final pass rate: X%
- Workspace: .claude/agent-evals/[name]/

You can re-run tests anytime with `/agent-architect test [name]`.
```
