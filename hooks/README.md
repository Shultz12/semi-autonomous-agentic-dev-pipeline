# Hooks

Lifecycle hooks that enforce safety and quality constraints across the agentic pipeline. Hooks are configured in `.claude/settings.json` under the `hooks` key and execute at specific points in Claude Code's tool/subagent lifecycle.

## Hooks in This Directory

| Hook | Lifecycle Event | Purpose |
|------|-----------------|---------|
| `enforce-subagent-output.sh` | SubagentStop | Blocks output-producing subagents from returning until their output file exists |
| `validate-bash-command.sh` | PreToolUse (Bash) | Validates Bash commands before execution |

---

## enforce-subagent-output.sh

Prevents subagents from returning empty-handed when they're supposed to produce a persistent output file. This is the only mechanism that guarantees pipeline-critical artifacts (review reports, phase summaries, investigations, plans, audit reports) actually exist after a subagent runs.

### The Problem

Subagents in the pipeline produce persistent files that downstream agents consume (e.g., the orchestrator routes based on a code-reviewer's verdict file). When a subagent finishes its analysis and returns a conversational summary instead of writing the file, the pipeline breaks: the next agent has nothing to read, and the orchestrator must detect the gap and re-dispatch.

This failure mode is especially common for agents with heavy read-analyze workloads — by the time analysis completes, the agent has built conversational momentum and forgets to write the file.

### The Solution: Two Enforcement Layers

**Layer 1 — Registry-based enforcement:** A registry file lists all agent types that MUST produce output files. The hook checks this registry on every SubagentStop. If a registered agent tries to stop without registering its output path, the hook blocks the return with explicit instructions to register and write.

**Layer 2 — Manifest-based verification:** Once an agent registers its output path (via `/tmp/.claude-agent-output-target`), the hook verifies the file exists at that path before allowing the agent to stop. If the file doesn't exist, the hook blocks again.

The two layers combine to make enforcement self-reliant: the hook independently knows which agents must produce files (Layer 1) and verifies they actually did so (Layer 2). The agent cannot bypass enforcement by skipping registration.

### How It Works

```
Subagent calls Stop → SubagentStop hook fires
                          │
                          ▼
        ┌─── Read /tmp/.claude-agent-output-target
        │    Read .claude/hooks/output-required-agents.json
        │    Extract agent_type from input JSON
        │
        ▼
   Is agent_type in registry?
        │
        ├── No, no manifest → exit 0 (allow stop)
        │
        ├── Yes, no manifest →
        │     BLOCK with message:
        │     "Register your output path AND write your file before returning"
        │
        ├── Manifest exists, target file exists → exit 0 (allow stop)
        │
        └── Manifest exists, target file missing →
              BLOCK with message:
              "Required output file not written. Expected: <path>"
```

After 2 failed block attempts, the safety valve releases the agent to prevent infinite loops.

### Agent Protocol

Agents register their expected output path early in their workflow by writing it to the manifest file:

```bash
echo "<full-output-file-path>" > /tmp/.claude-agent-output-target
```

Then they write their output file at that exact path. The hook verifies both the manifest and the target file before allowing return.

### output-required-agents.json

The registry of agent types that must produce output files. Format: a JSON array of agent name strings.

```json
["agent-auditor", "code-investigator", "code-reviewer", "design-auditor", "developer", "domain-auditor", "plan-auditor", "plan-architect", "quality-analyst", "spec-auditor", "state-manager", "test-runner"]
```

**To add a new agent to enforcement:**
1. Add the agent's name (matching the `name` field in its YAML frontmatter) to the array
2. Ensure the agent registers its output path early in its workflow
3. Ensure the agent has a Completion Gate section in its definition
4. Ensure the agent's "Never Do" / "Safety Boundaries" includes a constraint against returning without writing

**To remove an agent from enforcement:** simply remove it from the array. The hook will exit silently for that agent type.

### Files

| File | Purpose |
|------|---------|
| `enforce-subagent-output.sh` | The hook script |
| `output-required-agents.json` | Registry of agents subject to enforcement |
| `/tmp/.claude-agent-output-target` | Per-invocation manifest written by the agent |
| `/tmp/.claude-agent-stop-counter` | Per-invocation block attempt counter (auto-cleaned) |

---

## validate-bash-command.sh

PreToolUse hook for the Bash tool. Validates commands before they run, blocking unsafe or disallowed patterns. See the script header for the validation rules.

---

## Adding a New Hook

1. Create the hook script in this directory
2. Make it executable and use bash shebang: `#!/usr/bin/env bash`
3. Read input JSON from stdin: `INPUT=$(cat)`
4. Exit 0 to allow, exit 2 to block (stderr is fed back to the agent)
5. Register it in `.claude/settings.json` under the appropriate `hooks` event
6. Document it in this README
