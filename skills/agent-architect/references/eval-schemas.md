# Eval Schemas

JSON schemas for the behavioral testing infrastructure.

---

## evals.json

Test case definitions. Located at `.claude/agent-evals/<agent-name>/evals/evals.json`.

```json
{
  "agent_name": "code-reviewer",
  "agent_type": "sub-agent",
  "agent_path": ".claude/agents/code-reviewer/code-reviewer.md",
  "evals": [
    {
      "id": 1,
      "name": "lint-failure-diagnosis",
      "prompt": "Review the verification failure in phase 3. The lint output is...",
      "expected_output": "A structured diagnosis with root cause and fix recommendations",
      "expectations": [
        "The output identifies the specific lint rule that failed",
        "The output recommends a concrete fix, not just 'fix the lint error'",
        "The agent read the failing file before diagnosing"
      ]
    }
  ]
}
```

**Fields:**
- `agent_name`: Name matching the agent's definition
- `agent_type`: `"sub-agent"` or `"skill"`
- `agent_path`: Path to the agent's main definition file
- `evals[].id`: Unique integer identifier
- `evals[].name`: Kebab-case descriptive name (used in directory names)
- `evals[].prompt`: The task prompt to send to the agent
- `evals[].expected_output`: Human-readable description of success
- `evals[].expectations`: List of verifiable behavioral assertions

---

## eval_metadata.json

Per-eval metadata. Located at `iteration-N/eval-<name>/eval_metadata.json`.

```json
{
  "eval_id": 1,
  "eval_name": "lint-failure-diagnosis",
  "prompt": "Review the verification failure in phase 3..."
}
```

---

## grading.json

Output from the behavior-grader. Located at `iteration-N/eval-<name>/with_agent/run-1/grading.json`.

```json
{
  "expectations": [
    {
      "text": "The agent read the failing file before diagnosing",
      "passed": true,
      "evidence": "Transcript Step 2: 'Tool: Read - src/utils/parser.ts'"
    }
  ],
  "summary": {
    "passed": 2,
    "failed": 1,
    "total": 3,
    "pass_rate": 0.67
  },
  "execution_metrics": {
    "tool_calls": { "Read": 5, "Grep": 2 },
    "total_tool_calls": 7,
    "total_steps": 4,
    "errors_encountered": 0,
    "output_chars": 8200,
    "transcript_chars": 4500
  },
  "timing": {
    "total_duration_seconds": 45.0
  },
  "claims": [
    {
      "claim": "Identified 3 lint violations",
      "type": "factual",
      "verified": true,
      "evidence": "Output lists exactly 3 violations matching the lint output"
    }
  ],
  "user_notes_summary": {
    "uncertainties": [],
    "needs_review": [],
    "workarounds": []
  },
  "eval_feedback": {
    "suggestions": [],
    "overall": "Assertions are well-targeted for this eval."
  }
}
```

**Fields:**
- `expectations[]`: Graded assertions with evidence
- `summary`: Aggregate pass/fail counts and rate
- `execution_metrics`: Tool usage and output size
- `timing`: Wall clock timing from timing.json
- `claims`: Extracted and verified claims from the output
- `user_notes_summary`: Issues flagged by the executor
- `eval_feedback`: Improvement suggestions for the assertions (only when warranted)

---

## timing.json

Wall clock timing for a run. Located at `iteration-N/eval-<name>/with_agent/run-1/timing.json`.

**How to capture:** When a Agent subagent completes, the task notification includes `total_tokens` and `duration_ms`. Save these immediately — they are not persisted anywhere else.

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332,
  "total_duration_seconds": 23.3
}
```

---

## benchmark.json

Aggregated results from `aggregate_benchmark.py`. Located at `iteration-N/benchmark.json`.

```json
{
  "metadata": {
    "skill_name": "code-reviewer",
    "skill_path": ".claude/agents/code-reviewer/code-reviewer.md",
    "executor_model": "claude-sonnet-4-6",
    "analyzer_model": "claude-opus-4-6",
    "timestamp": "2026-03-09T10:30:00Z",
    "evals_run": [1, 2, 3],
    "runs_per_configuration": 1
  },
  "runs": [
    {
      "eval_id": 1,
      "eval_name": "lint-failure-diagnosis",
      "configuration": "with_agent",
      "run_number": 1,
      "result": {
        "pass_rate": 0.67,
        "passed": 2,
        "failed": 1,
        "total": 3,
        "time_seconds": 45.0,
        "tokens": 84852,
        "tool_calls": 7,
        "errors": 0
      },
      "expectations": [
        { "text": "...", "passed": true, "evidence": "..." }
      ],
      "notes": []
    }
  ],
  "run_summary": {
    "with_agent": {
      "pass_rate": { "mean": 0.67, "stddev": 0.0, "min": 0.67, "max": 0.67 },
      "time_seconds": { "mean": 45.0, "stddev": 0.0, "min": 45.0, "max": 45.0 },
      "tokens": { "mean": 84852, "stddev": 0, "min": 84852, "max": 84852 }
    },
    "delta": {
      "pass_rate": "+0.67",
      "time_seconds": "+45.0",
      "tokens": "+84852"
    }
  },
  "notes": [
    "Agent consistently reads files before analysis — strong process compliance"
  ]
}
```

**Fields:**
- `metadata`: Information about the test run
- `runs[]`: Individual run results with `configuration: "with_agent"`
- `run_summary`: Statistical aggregates (single-config, delta is absolute values)
- `notes`: Freeform observations from the behavior-analyzer

**Important:** The viewer reads field names exactly. Always use `configuration` (not `config`), and nest `pass_rate` under `result` (not at top level).

---

## Workspace Directory Structure

```
.claude/agent-evals/<agent-name>/
├── evals/
│   └── evals.json                          # Test case definitions
├── iteration-1/
│   ├── eval-lint-failure-diagnosis/
│   │   ├── eval_metadata.json              # Eval prompt and ID
│   │   └── with_agent/
│   │       └── run-1/
│   │           ├── outputs/                # Files the agent produced
│   │           │   └── transcript.md       # Execution transcript
│   │           ├── grading.json            # Grader output
│   │           └── timing.json             # Token/duration metrics
│   ├── eval-phase-review/
│   │   └── ...
│   ├── benchmark.json                      # Aggregated statistics
│   ├── benchmark.md                        # Human-readable summary
│   ├── notes.json                          # Analyzer observations
│   ├── review.html                         # Standalone viewer
│   └── feedback.json                       # User feedback from viewer
├── iteration-2/
│   └── ...                                 # After fixes, re-run
└── ...
```
