#!/usr/bin/env bash
# protect-env-files.sh — PreToolUse guard (user-level).
#
# Deterministically blocks the agent from READING secret env files
# (.env, .env.local, .env.development, .env.production, .env.<anything>)
# across the Read / Grep / Bash tools, while still allowing .env.example
# (and any *.example variant) to be read.
#
# Registered in .claude/settings.json under hooks.PreToolUse with
# matcher "Read|Grep|Bash". Emits a PreToolUse "deny" decision on a match.
#
# A protected basename is: exactly ".env", OR ".env.<x>" whose name does
# NOT end in ".example". Tokens like ".environment" or "config.env" are
# NOT protected (they are not .env-style dotfiles).
#
# JSON is parsed with sed (no jq dependency), matching the convention of
# validate-bash-command.sh.

INPUT="$(cat)"

# tool_name (string value)
TOOL="$(printf '%s' "$INPUT" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"

case "$TOOL" in
  Read|Edit|Write|NotebookEdit)
    CAND="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
    [ -z "$CAND" ] && CAND="$(printf '%s' "$INPUT" | sed -n 's/.*"notebook_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
    ;;
  Grep)
    # Only the search PATH can read a file's contents; the regex/glob
    # patterns are not file references (don't block a search FOR ".env").
    CAND="$(printf '%s' "$INPUT" | sed -n 's/.*"path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
    ;;
  Bash)
    CAND="$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)"/\1/p' | sed 's/\\"/"/g')"
    ;;
  *)
    exit 0
    ;;
esac

[ -z "$CAND" ] && exit 0

# Normalize: backslashes -> "/"; every char that can't be part of a path
# token -> space. Then word-split on whitespace.
NORM="$(printf '%s' "$CAND" | tr '\\' '/' | tr -c 'A-Za-z0-9._/-' ' ')"

PROTECTED=0
for tok in $NORM; do
  base="${tok##*/}"            # basename: text after the last "/"
  case "$base" in
    .env)
      PROTECTED=1; break ;;
    .env.*)
      case "$base" in
        *.example) : ;;        # .env.example / .env.<x>.example — allowed
        *) PROTECTED=1; break ;;
      esac ;;
  esac
done

if [ "$PROTECTED" -eq 1 ]; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Reading secret env files (.env, .env.local, .env.development, .env.production, ...) is blocked by .claude/hooks/protect-env-files.sh. Use .env.example instead."}}
JSON
  exit 0
fi

exit 0
