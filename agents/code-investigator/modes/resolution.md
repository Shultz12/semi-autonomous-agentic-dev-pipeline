# Resolution Mode

Appends user resolutions to existing investigation files for Level 3 and Level 4 findings.

## Workflow

### Step 1: Parse Input

Extract from the orchestrator's prompt:
- `Mode`: must be `resolution`
- `Investigation File Path`: path to the existing investigation file
- `Phase`: phase number and name in the form `[N]: [phase-name]` — used by Step 6 commit subject and the Step 7 return template
- `Level`: LEVEL_3 or LEVEL_4
- `Resolution`: user's chosen option (LEVEL_3) or decision (LEVEL_4)
- `Rationale`: user's reasoning (if provided)

### Step 2: Normalize Investigation File

Handles the case where a prior dispatch appended a resolution but crashed before committing. Run via Bash, substituting the actual Investigation File Path:

```
if [ -f "<path>" ]; then
  if git ls-files --error-unmatch "<path>" >/dev/null 2>&1; then
    git checkout HEAD -- "<path>"
  else
    rm -f "<path>"
  fi
fi
```

- File doesn't exist → no-op (Step 3 validation will fail; return `Commit: none`).
- File tracked at HEAD → discards uncommitted changes, including any partial resolution from a crashed prior attempt; the validity checks in Step 3 then see the file's pre-resolution state.
- File untracked → `rm` removes the orphan (it was never in the audit trail).

### Step 3: Read Investigation File

Read the file at `Investigation File Path`. Verify:
1. File exists
2. Contains LEVEL_3 or LEVEL_4 finding matching the Level field
3. No resolution section already exists for this finding

If any check fails, report the issue in the return output and stop (skip Steps 4–6; return `Commit: none` in Step 7).

### Step 4: Translate Resolution to Fix Instructions

**For LEVEL_3:** Map the user's chosen option to concrete fix instructions.
- Read the option's "Affected Files" list from the investigation file
- Formulate specific fix instructions for each affected file
- Use Read/Grep to verify file paths and line numbers are still accurate

**For LEVEL_4:** Translate the user's decision into actionable fix instructions.
- The user's input may be a hypothesis selection, a new approach, or domain clarification
- Formulate fix instructions based on what the user provided
- If the user's input is insufficient to formulate fixes, skip Steps 5–6 and return INSUFFICIENT in Step 7 (with `Commit: none`).

### Step 5: Append Resolution

Read the existing file, then Write the full file with the resolution section appended after the last section of the relevant attempt:

```markdown
### Resolution
**Resolved By:** user
**Choice:** [Option name or decision summary]
**Rationale:** [user's rationale, or "Not provided"]

**Fix Instructions:**
| # | File | Line | Action | Detail |
|---|------|------|--------|--------|
| 1 | [path] | [N] | [add/modify/remove] | [exact instruction] |

**Verification:**
- [commands to confirm fix]
```

### Step 6: Commit Investigation File

After the resolution section is appended (Step 5) and before returning, Read `.claude/skills/commit-to-git/SKILL.md` and follow it to commit the investigation file path-scoped. Pass:

- `Agent: code-investigator`
- `Path:` the Investigation File Path
- `Subject:` `investigate(<slug>): phase <N> resolution-level-<K>` where `<K>` is from the input `Level` field (3 or 4)

Where `<slug>` is the basename of the feature directory derived from `Investigation File Path` (the directory two levels up from `code-investigations/` — i.e., `.project/cycles/<slug>/execution/code-investigations/` → `<slug>`), and `<N>` is the phase number from the input.

Commit nothing else. If Step 3 validation failed or Step 4 produced no usable fixes (INSUFFICIENT path), do not run the commit — Step 7 reports `Commit: none`.

Capture the resulting short hash for Step 7; if the commit produced no change (the normalized file plus the fresh append reproduced byte-identical content to HEAD), record `skipped`. If the commit fails (lock contention, hook rejection, transient error), record `failed` and surface it in the return — never report a success hash for a commit that did not happen.

A failed commit must never block the return from happening; the investigation file is already updated on disk.

### Step 7: Return Structured Output

Return the structured message below to the orchestrator. `Commit:` semantics are documented in `code-investigator.md` Output Format.

**SUCCESS:**

```
Reporter: code-investigator
Mode: resolution
Phase: [N]: [phase-name]
Original Verdict: LEVEL_3 | LEVEL_4
Resolution: [chosen option or decision summary]
Investigation File: [Investigation File Path]
Commit: [short-hash | skipped | failed]
Target: code | test

### Fix Summary
[count] fixes in [count] files. [1 sentence overview]

### Verification
- [commands to confirm fix]
```

**INSUFFICIENT** (LEVEL_4 only — user input doesn't translate to fixes):

```
Reporter: code-investigator
Mode: resolution
Phase: [N]: [phase-name]
Original Verdict: LEVEL_4
Status: INSUFFICIENT
Investigation File: [Investigation File Path]
Commit: none

### What's Missing
[1-2 sentences: what additional input is needed to formulate fixes]
```
