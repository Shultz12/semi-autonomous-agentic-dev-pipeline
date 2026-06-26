# Output Enforcement

## Purpose

Prevent agents from returning without writing their mandatory output file. Uses a SubagentStop hook that mechanically blocks the agent from stopping until the file exists.

## When to Apply

Apply when the agent has a **mandatory output file** — a file it must write before returning to its caller. This includes:
- Report files (code reviews, audit reports, quality reports)
- Implementation reports (developer status reports)
- Investigation files
- Plan files
- Any persistent artifact that downstream agents or the orchestrator depend on

**Do NOT apply** when:
- The agent returns structured output inline only (no file write)
- The agent only modifies existing files (the hook checks existence, not modification)
- The agent's file output is conditional (written only in some code paths)

## Implementation

Three components work together:

### 1. Completion Gate Section

Add to the agent definition, before the Workflow section:

```markdown
## Completion Gate

A SubagentStop hook blocks you from returning until your output file exists. Register the path early, write the file as soon as content is ready. If low on turns, write partial content — a partial file is better than no file.
```

### 2. Output Path Registration

Add to the agent's workflow, as early as the output path is known. The agent runs a Bash command to write the expected file path to a manifest:

```markdown
Register output path — run via Bash: `rm -f /tmp/.claude-agent-output-target /tmp/.claude-agent-stop-counter && echo "[output file path]" > /tmp/.claude-agent-output-target`
```

**Timing:** Register as early as possible — ideally in Step 1 (Load Knowledge) or immediately after parsing input. For agents where the filename is constructed mid-workflow (e.g., timestamp-based filenames), register right after construction.

**Path format:** Use the same path format the Write tool will use. On Windows/Git Bash, use `$HOME` for user-level paths.

**Collision handling:** If the filename might change due to collision detection (e.g., appending a letter suffix), update the manifest before writing: `echo "[new path]" > /tmp/.claude-agent-output-target`

### 3. Bash Tool Requirement

The agent needs the Bash tool to run the registration command. If the agent doesn't already have Bash, add it to the tools list.

## How the Hook Works

The SubagentStop hook at `.claude/hooks/enforce-subagent-output.sh`:
1. Reads the manifest at `/tmp/.claude-agent-output-target`
2. If no manifest exists — no-op, allows stop (safe for non-enforced agents)
3. If manifest exists — checks if the target file exists
4. If file exists — cleans up manifest, allows stop
5. If file missing — blocks the stop (exit code 2), injects error message telling the agent to write the file
6. On second block attempt — allows stop to prevent infinite loops

## Rationale

Agents that do heavy analysis or implementation work (many turns of reading, running diagnostics, writing code) often exhaust their attention budget by the time they reach the final "write output file" step. This causes them to return without the file, forcing expensive re-invocations. The SubagentStop hook provides mechanical enforcement — the agent literally cannot return until the file exists.

## Example

**GOOD** — Agent registers early and writes before returning:
```markdown
### Step 1: Load Knowledge
1. Read essentials/rules.md
2. Register output path — run via Bash: `rm -f /tmp/.claude-agent-output-target /tmp/.claude-agent-stop-counter && echo ".project/cycles/auth/execution/code-reviews/phase-3-code-review-attempt-1.md" > /tmp/.claude-agent-output-target`

[... analysis work ...]

### Step 6: Write Review File
[writes the file]

### Step 7: Return Message
[returns structured output — SubagentStop hook allows this because file exists]
```

**BAD** — Agent skips registration or defers to the end:
```markdown
### Step 1: Load Knowledge
1. Read essentials/rules.md
[no registration]

[... analysis work ...]

### Step 7: Return Message
[returns without writing file — no hook enforcement, file missing]
```
