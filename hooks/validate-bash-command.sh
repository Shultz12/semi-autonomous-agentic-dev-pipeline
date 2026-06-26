#!/usr/bin/env bash
# Bash command allowlist validation hook for Claude Code
# Called as a PreToolUse hook for the Bash tool.
# Reads JSON from stdin: {"tool_name": "Bash", "tool_input": {"command": "..."}}
# Exit 0 = allowed, Exit 2 = blocked with message

set -euo pipefail

# Read stdin
INPUT=$(cat)

# Extract the command string from JSON input
# Uses parameter expansion to avoid dependency on jq
COMMAND=$(echo "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/p' | sed 's/\\"/"/g')

# If we couldn't extract a command, allow it (fail open for non-standard input)
if [ -z "$COMMAND" ]; then
  exit 0
fi

# Strip unnecessary "cd <path> && " prefix before matching.
# Agents sometimes prepend cd when the working directory is already correct.
# This avoids wasting tokens on a blocked call + retry.
COMMAND=$(echo "$COMMAND" | sed 's/^cd [^&]* && //')

# Allowlist patterns — each pattern is checked as a prefix or exact match
# Keep this list in sync with essentials/dev-rules.md § Permitted Resolution Commands
ALLOWED_PATTERNS=(
  # Global verification
  "npm run lint"
  "npm run build"
  "npm test"
  "npm run test:unit"
  "npm run dev"
  "npm install"
  "npm ci"

  # Workspace package scripts addressed via --prefix (avoids a cd prefix)
  "npm --prefix frontend run"
  "npm --prefix backend run"

  # pnpm / corepack / node (monorepo workspace tooling)
  "pnpm"
  "corepack"
  "node"
  "npx only-allow"
  "npx shadcn"
  "npx tsx"
  "npx tsc"

  # MERUKAZ OCR dev harness — offline extraction iteration loop
  # (record-once / replay-forever cassettes; boots a headless Nest context)
  "pnpm ocr-lab"

  # Directory creation
  "mkdir"

  # Sleep (retry backoff for transient Windows EPERM on Prisma generate, etc.)
  "sleep"

  # Piping canned answers into interactive CLIs (e.g. `yes n | pnpm dlx shadcn add ...`)
  "yes"
  "printf"

  # Process inspection (diagnosing locked files on Windows)
  "tasklist"
  "powershell"
  "netstat"

  # Process termination (e.g. freeing dev-server ports 5172/5173)
  "taskkill"

  # Prisma commands
  "npx prisma"

  # SvelteKit
  "npx svelte-kit sync"

  # Chained backend commands
  "cd backend && npm run lint"
  "cd backend && npm run build"
  "cd backend && npm test"
  "cd backend && npx prisma generate"
  "cd backend && npx prisma validate"
  "cd backend && npx prisma migrate dev --name"

  # Chained frontend commands
  "cd frontend && npm run lint"
  "cd frontend && npm run build"
  "cd frontend && npm run test:unit"
  "cd frontend && npx prettier"

  # Read-only git (for context, not mutations)
  "git log"
  "git diff"
  "git status"
  "git remote"

  # GitHub CLI (PRs, issues, API)
  "gh"

  # Google Cloud CLI (Vision API provisioning, auth, service accounts)
  "gcloud"

  # Navigation
  "cd"
  "pwd"

  # File system read-only operations
  "ls"
  "test"
  "find"
  "diff"
  "echo"
  "file"
  "head"
  "xxd"

  # File copy (needed for skill/agent deployment to user level)
  "cp"

  # File move/rename
  "mv"

  # File removal
  "rm"

  # tar (for extracting design archives etc.)
  "tar"

  # Git staging (add one, multiple, or all files)
  "git add"
  "git -C"

  # Git move/rename (history-preserving file moves, e.g. domain reorg codemods)
  "git mv"

  # Git commit
  "git commit"

  # Git push
  "git push"

  # Git clone (for external repo research)
  "git clone"

  # Git branch management (orchestrator needs these)
  "git checkout"
  "git branch"
  "git rev-parse"
  "git merge"
  "git worktree"
  "git stash"
  "git check-ignore"
  "git clean"

  # Git repository initialization & local config
  "git init"
  "git config"
  "git ls-files"

  # Firecrawl for documentation scraping
  "firecrawl"

  # curl (HTTP requests, e.g. n8n REST API)
  "curl"

  # docker
  "docker"

  # Python one-liners (JSON parsing etc.)
  "python"
  "python3"

  # Gherkin linting for BDD specs
  "npx gherkin-lint"
  "npx @cucumber/gherkin-utils"
)

# Check command against allowlist (prefix matching)
for pattern in "${ALLOWED_PATTERNS[@]}"; do
  if [[ "$COMMAND" == "$pattern"* ]]; then
    exit 0
  fi
done

# Command not on allowlist — block it
ALLOWED_LIST=$(printf "  - %s\n" "${ALLOWED_PATTERNS[@]}")

echo "Command not on permitted allowlist: \"$COMMAND\""
echo ""
echo "Allowed commands:"
echo "$ALLOWED_LIST"
echo ""
echo "If this command is needed, ask the user to update .claude/hooks/validate-bash-command.sh"

exit 2
