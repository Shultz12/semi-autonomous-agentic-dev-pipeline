#!/usr/bin/env bash
# SubagentStop hook: blocks subagent from returning until required output file is written.
#
# Two enforcement layers:
#   1. Registry-based: agents listed in output-required-agents.json MUST produce output.
#      If they try to stop without registering a manifest, they're blocked.
#   2. Manifest-based: if a manifest exists at /tmp/.claude-agent-output-target,
#      the target file must exist before the agent can stop.
#
# Protocol:
#   Agents register their expected output path by writing it to /tmp/.claude-agent-output-target.
#   Registered agents that skip this step are caught by the registry check.
#
# Input (JSON on stdin): { "agent_type": "code-reviewer", ... }
# Exit 0 = allow stop, Exit 2 = block stop (stderr fed back to agent).

set -euo pipefail

# Resolve paths relative to this script's own location so the hook works
# whether the pipeline is installed at user level or project level.
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HOOK_DIR")"

MANIFEST="/tmp/.claude-agent-output-target"
COUNTER="/tmp/.claude-agent-stop-counter"
REGISTRY="$HOOK_DIR/output-required-agents.json"
INPUT=$(cat)

# Extract agent_type from input
AGENT_TYPE=$(echo "$INPUT" | sed -n 's/.*"agent_type"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' || true)

# Check if agent is in the output-required registry
REGISTERED=false
if [ -f "$REGISTRY" ] && [ -n "$AGENT_TYPE" ]; then
  if grep -q "\"$AGENT_TYPE\"" "$REGISTRY" 2>/dev/null; then
    REGISTERED=true
  fi
fi

# Not registered and no manifest = not enforced
if [ "$REGISTERED" = false ] && [ ! -f "$MANIFEST" ]; then
  exit 0
fi

# Registered but no manifest = agent skipped registration → block
if [ "$REGISTERED" = true ] && [ ! -f "$MANIFEST" ]; then
  ATTEMPTS=0
  if [ -f "$COUNTER" ]; then
    ATTEMPTS=$(tr -d '\r\n' < "$COUNTER")
  fi

  if [ "$ATTEMPTS" -ge 2 ]; then
    rm -f "$COUNTER"
    exit 0
  fi

  echo $((ATTEMPTS + 1)) > "$COUNTER"
  echo "STOP BLOCKED (${AGENT_TYPE}): You are a registered output-producing agent." >&2
  echo "You MUST write your output file before returning." >&2
  echo "1. Register your output path: echo \"<output-file-path>\" > /tmp/.claude-agent-output-target" >&2
  echo "2. Write your output file using the Write tool" >&2
  echo "3. Then return your structured message" >&2
  exit 2
fi

# From here: manifest exists
TARGET=$(tr -d '\r\n' < "$MANIFEST" | sed 's|\\|/|g')

# Empty manifest = no enforcement
if [ -z "$TARGET" ]; then
  rm -f "$MANIFEST" "$COUNTER"
  exit 0
fi

# Target file exists = success
if [ -f "$TARGET" ]; then
  # Commit-required logging (staging: log only, never blocks).
  # Records whether the manifest path is tracked at HEAD so we can audit how
  # often committing agents stop without committing their declared artifact.
  COMMIT_REGISTRY="$HOOK_DIR/commit-required-agents.json"
  if [ -f "$COMMIT_REGISTRY" ] && [ -n "$AGENT_TYPE" ] && grep -q "\"$AGENT_TYPE\"" "$COMMIT_REGISTRY" 2>/dev/null; then
    COMMIT_LOG="$ROOT/logs/commit-hook.log"
    mkdir -p "$(dirname "$COMMIT_LOG")"
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
      RESULT="NO_REPO  "
    elif git ls-files --error-unmatch "$TARGET" >/dev/null 2>&1; then
      RESULT="TRACKED  "
    else
      RESULT="UNTRACKED"
    fi
    printf '%s\t%s\t%s\t%s\n' "$TIMESTAMP" "$RESULT" "$AGENT_TYPE" "$TARGET" >> "$COMMIT_LOG"
  fi

  rm -f "$MANIFEST" "$COUNTER"
  exit 0
fi

# Target missing — check attempt counter
ATTEMPTS=0
if [ -f "$COUNTER" ]; then
  ATTEMPTS=$(tr -d '\r\n' < "$COUNTER")
fi

# After 2 failed attempts, allow stop to prevent infinite loop
if [ "$ATTEMPTS" -ge 2 ]; then
  rm -f "$MANIFEST" "$COUNTER"
  exit 0
fi

# Block
echo $((ATTEMPTS + 1)) > "$COUNTER"
echo "STOP BLOCKED (${AGENT_TYPE:-agent}): Required output file not written." >&2
echo "Expected: $TARGET" >&2
echo "Write this file using the Write tool before returning." >&2
exit 2
