#!/bin/sh
# install.sh — add-only installer for the Agentic Development Pipeline.
#
# Wires the pipeline's three hooks into your Claude Code settings and (for a
# project-level install) gitignores the vendored .claude/ clone. It is strictly
# ADDITIVE: it never overwrites or deletes a file you already have, and (at --user
# level) it stops with an alert if it finds foreign agents/ or skills/ directories
# that could collide.
#
# Usage:
#   bash <pipeline-dir>/install.sh [--project | --user]
#
#   --project  (default flow) The pipeline was cloned into <project>/.claude
#              (`git clone <url> .claude`). Wires hooks into
#              <project>/.claude/settings.json using ${CLAUDE_PROJECT_DIR} and
#              gitignores .claude/ in the project.
#   --user     The pipeline was cloned to a temp dir; merge it into ~/.claude
#              and wire hooks into ~/.claude/settings.json using $HOME.
#
# If no level flag is given, the installer prompts for one.
#
# Idempotent: re-running adds nothing already present. No rm, no overwrite.

set -u

# ----------------------------------------------------------------------------
# helpers
# ----------------------------------------------------------------------------
err()  { printf '%s\n' "$*" >&2; }
die()  { err "ERROR: $*"; exit 1; }
info() { printf '%s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }
realdir() { ( cd "$1" 2>/dev/null && pwd -P ); }
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

# Print the first python interpreter that ACTUALLY RUNS (not just resolves on
# PATH) and can import the stdlib modules we need. On Windows, `python3` is often
# a non-functional Microsoft Store "app execution alias" that resolves via
# `command -v` but errors when invoked — so we functionally test each candidate.
pick_python() {
  for cand in python3 python python3.13 python3.12 python3.11; do
    command -v "$cand" >/dev/null 2>&1 || continue
    if "$cand" -c 'import json, tempfile, os' >/dev/null 2>&1; then
      printf '%s' "$cand"; return 0
    fi
  done
  return 1
}

# ----------------------------------------------------------------------------
# locate the pipeline (this script's own directory) and verify it
# ----------------------------------------------------------------------------
SCRIPT_DIR=$( CDPATH= cd -- "$(dirname -- "$0")" && pwd -P ) \
  || die "could not resolve the installer's own directory."
PIPELINE_DIR="$SCRIPT_DIR"

[ -d "$PIPELINE_DIR/agents" ] && [ -d "$PIPELINE_DIR/skills" ] \
  && [ -d "$PIPELINE_DIR/hooks" ] && [ -f "$PIPELINE_DIR/skills/orchestrator/SKILL.md" ] \
  || die "this does not look like the pipeline directory ($PIPELINE_DIR).
Run install.sh from the cloned pipeline (it must contain agents/, skills/, hooks/)."

# ----------------------------------------------------------------------------
# parse / prompt for the install level
# ----------------------------------------------------------------------------
MODE=""
case "${1:-}" in
  --project) MODE="project" ;;
  --user)    MODE="user" ;;
  "")        MODE="" ;;
  *)         die "unknown argument '$1'. Use --project or --user." ;;
esac

if [ -z "$MODE" ]; then
  if [ ! -t 0 ]; then
    die "no install level given and not running interactively.
Pass --project (scope to one repo) or --user (merge into ~/.claude)."
  fi
  printf 'Install level — [p]roject (this repo) or [u]ser (~/.claude)? '
  read -r ANS
  case "$ANS" in
    p|P|project|--project) MODE="project" ;;
    u|U|user|--user)       MODE="user" ;;
    *) die "unrecognized choice '$ANS'. Re-run with --project or --user." ;;
  esac
fi

# ----------------------------------------------------------------------------
# resolve the target and the hook command base for the chosen level
# ----------------------------------------------------------------------------
if [ "$MODE" = "project" ]; then
  # Project flow: the pipeline IS <project>/.claude. No copy — files are in place.
  [ "$(basename "$PIPELINE_DIR")" = ".claude" ] \
    || die "for --project the pipeline must live at <project>/.claude
(clone it with: git clone <url> .claude), because the hooks resolve via
\${CLAUDE_PROJECT_DIR}/.claude/. Found it at: $PIPELINE_DIR"
  TARGET="$PIPELINE_DIR"
  PROJECT_ROOT=$(dirname "$PIPELINE_DIR")
  HOOK_BASE='${CLAUDE_PROJECT_DIR}/.claude/hooks/'
else
  # User flow: merge the pipeline into ~/.claude.
  [ -n "${HOME:-}" ] || die "\$HOME is not set; cannot resolve ~/.claude for --user."
  TARGET="$HOME/.claude"
  HOOK_BASE='$HOME/.claude/hooks/'
fi
SETTINGS="$TARGET/settings.json"

info "Installing the Agentic Development Pipeline (level: $MODE)."
info "  Pipeline:  $PIPELINE_DIR"
info "  Target:    $TARGET"
info ""

# ----------------------------------------------------------------------------
# collision guard + additive merge (only when target != pipeline, i.e. --user)
# ----------------------------------------------------------------------------
SAME_DIR="no"
if [ -d "$TARGET" ]; then
  RP_PIPE=$(realdir "$PIPELINE_DIR"); RP_TARGET=$(realdir "$TARGET")
  [ -n "$RP_PIPE" ] && [ "$RP_PIPE" = "$RP_TARGET" ] && SAME_DIR="yes"
fi

# list the basenames the pipeline ships under a given subdir (agents|skills)
pipeline_entries() {
  for e in "$PIPELINE_DIR/$1"/*; do
    [ -e "$e" ] || continue
    basename "$e"
  done
}

# names not shipped by the pipeline = foreign content that could collide/shadow
foreign_entries() {  # $1 = subdir (agents|skills)
  sub="$1"
  [ -d "$TARGET/$sub" ] || return 0
  for e in "$TARGET/$sub"/*; do
    [ -e "$e" ] || continue
    b=$(basename "$e")
    match=no
    for p in $(pipeline_entries "$sub"); do          # exact-name compare (slugs)
      [ "$b" = "$p" ] && { match=yes; break; }
    done
    [ "$match" = no ] && printf '%s/%s\n' "$sub" "$b"  # not ours — report as foreign
  done
}

if [ "$MODE" = "user" ] && [ "$SAME_DIR" = "no" ]; then
  FOREIGN="$(foreign_entries agents; foreign_entries skills)"
  if [ -n "$FOREIGN" ]; then
    err "Collision guard tripped — $TARGET already contains agents/ or skills/"
    err "directories that are NOT part of this pipeline:"
    printf '%s\n' "$FOREIGN" | sed 's/^/    /' >&2
    err ""
    err "An additive merge (cp -Rn) would leave these half-merged or let them"
    err "shadow the pipeline's own files. Nothing has been changed."
    err "Recommended: install into a .claude/ with no agents/ or skills/ of your"
    err "own — e.g. install at --project level, or move your custom agents aside"
    err "first. See INSTALL.md (Collisions)."
    exit 1
  fi

  info "Merging pipeline files into $TARGET (additive, no-clobber)..."
  mkdir -p "$TARGET" || die "could not create $TARGET"
  for sub in agents skills hooks documentation; do
    [ -d "$PIPELINE_DIR/$sub" ] || continue
    mkdir -p "$TARGET/$sub" || die "could not create $TARGET/$sub"
    # cp -Rn: recursive, no-clobber. Copies CONTENTS into the existing dir so a
    # pre-existing $TARGET/.git and any same-named files you have are preserved.
    # cp -n returns 0 when it skips an existing file, so a non-zero status here is
    # a GENUINE failure (permissions, disk) — abort rather than report a false success.
    if ! cp -Rn "$PIPELINE_DIR/$sub/." "$TARGET/$sub/"; then
      die "failed to merge $sub/ into $TARGET — nothing further changed."
    fi
  done
  info "  Merged: agents/ skills/ hooks/ documentation/ (existing files kept)."
  # A wired hook that already exists in the target is KEPT by no-clobber, so
  # settings.json would point at that (possibly stale/foreign) copy. Warn if so.
  for h in validate-bash-command protect-env-files enforce-subagent-output; do
    if [ -f "$TARGET/hooks/$h.sh" ] && [ -f "$PIPELINE_DIR/hooks/$h.sh" ] \
       && ! cmp -s "$TARGET/hooks/$h.sh" "$PIPELINE_DIR/hooks/$h.sh"; then
      info "  NOTE: hooks/$h.sh already existed and differs from the pipeline's copy —"
      info "        the no-clobber merge kept yours; the wired hook runs that version."
      info "        Remove it and re-run if you want the pipeline's."
    fi
  done
  info ""
elif [ "$MODE" = "user" ] && [ "$SAME_DIR" = "yes" ]; then
  info "Pipeline already lives at $TARGET — skipping the merge (files in place)."
  info ""
fi

# ----------------------------------------------------------------------------
# build the three hook command strings + dedup signatures for this level
# ----------------------------------------------------------------------------
CMD1="bash \"${HOOK_BASE}validate-bash-command.sh\"";  SIG1="${HOOK_BASE}validate-bash-command.sh"
CMD2="bash \"${HOOK_BASE}protect-env-files.sh\"";      SIG2="${HOOK_BASE}protect-env-files.sh"
CMD3="bash \"${HOOK_BASE}enforce-subagent-output.sh\"";SIG3="${HOOK_BASE}enforce-subagent-output.sh"
MATCHER2="Read|Edit|Write|NotebookEdit|Grep|Bash"

print_snippet() {
  c1=$(json_escape "$CMD1"); c2=$(json_escape "$CMD2"); c3=$(json_escape "$CMD3")
  err ""
  err "Could not safely merge into $SETTINGS automatically."
  err "Add these three hooks to your settings.json by hand (merge into any"
  err "existing \"hooks\" block — do not replace it):"
  err ""
  cat >&2 <<EOF
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "$c1" } ] },
      { "matcher": "$MATCHER2", "hooks": [ { "type": "command", "command": "$c2" } ] }
    ],
    "SubagentStop": [
      { "hooks": [ { "type": "command", "command": "$c3" } ] }
    ]
  }
EOF
  err ""
}

write_minimal() {
  c1=$(json_escape "$CMD1"); c2=$(json_escape "$CMD2"); c3=$(json_escape "$CMD3")
  TMP="$SETTINGS.tmp.$$"
  cat > "$TMP" <<EOF
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "$c1" } ] },
      { "matcher": "$MATCHER2", "hooks": [ { "type": "command", "command": "$c2" } ] }
    ],
    "SubagentStop": [
      { "hooks": [ { "type": "command", "command": "$c3" } ] }
    ]
  }
}
EOF
  mv "$TMP" "$SETTINGS" || { rm -f "$TMP"; return 1; }
}

merge_with_jq() {
  TMP="$SETTINGS.tmp.$$"
  { cat "$SETTINGS" 2>/dev/null || printf '%s' '{}'; } | jq \
    --arg c1 "$CMD1" --arg s1 "$SIG1" \
    --arg c2 "$CMD2" --arg s2 "$SIG2" --arg m2 "$MATCHER2" \
    --arg c3 "$CMD3" --arg s3 "$SIG3" '
      def addhook($event; $group; $sig):
        .hooks = (.hooks // {})
        | .hooks[$event] = (.hooks[$event] // [])
        | if ([.hooks[$event][]?.hooks[]?.command // empty] | any(contains($sig)))
          then . else .hooks[$event] += [$group] end;
      addhook("PreToolUse"; {matcher:"Bash", hooks:[{type:"command",command:$c1}]}; $s1)
      | addhook("PreToolUse"; {matcher:$m2, hooks:[{type:"command",command:$c2}]}; $s2)
      | addhook("SubagentStop"; {hooks:[{type:"command",command:$c3}]}; $s3)
    ' > "$TMP" 2>/dev/null
  if [ $? -eq 0 ] && [ -s "$TMP" ]; then
    mv "$TMP" "$SETTINGS" || { rm -f "$TMP"; return 1; }
    return 0
  fi
  rm -f "$TMP"; return 1
}

merge_with_python() {
  py="$1"
  "$py" - "$SETTINGS" "$HOOK_BASE" "$MATCHER2" <<'PY'
import json, os, sys, tempfile
target, base, matcher2 = sys.argv[1], sys.argv[2], sys.argv[3]
specs = [
    ("PreToolUse", "Bash", "validate-bash-command.sh"),
    ("PreToolUse", matcher2, "protect-env-files.sh"),
    ("SubagentStop", None, "enforce-subagent-output.sh"),
]
try:
    with open(target) as f:
        data = json.load(f)
    if not isinstance(data, dict):
        sys.stderr.write("settings root is not a JSON object\n"); sys.exit(3)
except FileNotFoundError:
    data = {}
except (ValueError, json.JSONDecodeError):
    sys.stderr.write("settings.json is not valid JSON\n"); sys.exit(3)
hooks = data.setdefault("hooks", {})
for event, matcher, script in specs:
    cmd = 'bash "%s%s"' % (base, script)
    sig = base + script
    arr = hooks.setdefault(event, [])
    present = any(sig in (h.get("command", "") or "")
                  for g in arr if isinstance(g, dict)
                  for h in g.get("hooks", []) if isinstance(h, dict))
    if present:
        continue
    group = {"hooks": [{"type": "command", "command": cmd}]}
    if matcher is not None:
        group = {"matcher": matcher, "hooks": [{"type": "command", "command": cmd}]}
    arr.append(group)
d = os.path.dirname(os.path.abspath(target)) or "."
fd, tmp = tempfile.mkstemp(dir=d, suffix=".tmp")
with os.fdopen(fd, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
os.replace(tmp, target)
PY
}

# ----------------------------------------------------------------------------
# wire the hooks: jq -> python3/python -> sh fallback
# ----------------------------------------------------------------------------
info "Wiring hooks into $SETTINGS ..."
mkdir -p "$TARGET" || die "could not create $TARGET"
# Never replace an existing-but-unreadable settings.json (the jq path's {} fallback
# could otherwise clobber it). Absent is fine; present-and-unreadable aborts.
if [ -e "$SETTINGS" ] && [ ! -r "$SETTINGS" ]; then
  die "$SETTINGS exists but is not readable — refusing to risk overwriting it."
fi
WIRED="no"

PY="$(pick_python)" || PY=""
if have jq; then
  if merge_with_jq; then WIRED="yes"; else print_snippet; fi
elif [ -n "$PY" ]; then
  if merge_with_python "$PY"; then WIRED="yes"; else print_snippet; fi
else
  if [ -f "$SETTINGS" ]; then
    err "No jq or working python found and $SETTINGS already exists — cannot merge safely."
    print_snippet
  else
    write_minimal && WIRED="yes"
  fi
fi

if [ "$WIRED" = "yes" ]; then
  info "  Hooks present in settings.json (idempotent — existing keys/hooks preserved)."
else
  info "  Hooks NOT auto-wired — paste the snippet above into your settings.json."
fi
info ""

# ----------------------------------------------------------------------------
# gitignore the vendored clone (project level only) + alert
# ----------------------------------------------------------------------------
if [ "$MODE" = "project" ]; then
  if git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    if git -C "$PROJECT_ROOT" check-ignore -q .claude 2>/dev/null; then
      info "Gitignore: .claude/ is already ignored in this project."
    else
      printf '\n.claude/\n' >> "$PROJECT_ROOT/.gitignore"
      info "ALERT: appended '.claude/' to $PROJECT_ROOT/.gitignore."
      info "  The pipeline is a VENDORED CLONE, not your project's source — keep it"
      info "  out of your repo. Update it with:  git -C .claude pull"
      info "  To stop ignoring it, delete the '.claude/' line you just added."
    fi
  else
    info "Gitignore: $PROJECT_ROOT is not a git repository — skipping (.claude/ not ignored)."
  fi
  info ""
fi

# ----------------------------------------------------------------------------
# next steps
# ----------------------------------------------------------------------------
info "Done. Next steps:"
info "  1. Restart Claude Code (or run /hooks) so it picks up the new hooks."
info "  2. Run /hooks to confirm the three pipeline hooks are registered."
if [ "$MODE" = "project" ]; then
  info "  3. Update the pipeline later with:  git -C .claude pull"
else
  info "  3. Update later with:  git -C \"$PIPELINE_DIR\" pull && bash \"$PIPELINE_DIR/install.sh\" --user"
fi

# Exit non-zero when hooks were not auto-wired, so a non-interactive/CI caller can
# detect a partial install (the manual snippet was printed above).
[ "$WIRED" = "yes" ] || exit 3
exit 0
