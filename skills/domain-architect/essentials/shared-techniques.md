# Shared Techniques

Reusable workflows referenced by multiple modes.

## Review Integration

After creating or updating domain files — but **before announcing completion** — offer the user a review via the domain-auditor.

### Step 1: Present Review Options

Use `AskUserQuestion` with these 3 options:

- **Question:** "Would you like to run the domain auditor to review the created/updated domain?"
- **Header:** "Review"
- **Options:**
  1. **"Autonomous (Recommended)"** — Run domain-auditor and apply all fixes automatically
  2. **"User-guided"** — Run domain-auditor, let user pick which fixes to apply
  3. **"Skip review"** — Don't run auditor

### Step 2: Execute Chosen Path

#### Path 1: Autonomous

1. Spawn `domain-auditor` via the Task tool:
   - `subagent_type: "domain-auditor"`
   - `prompt: "Review the domain: <name>"` (where `<name>` is the kebab-case domain name)
   - `description: "Review <name> domain"`
2. Parse the returned results
3. If **PASS** (no CRITICAL or ERROR issues):
   - Present the auditor's summary to the user
   - Inform user that the full report is available in the handoff file
   - Announce completion
4. If **issues found**:
   - Apply ALL recommended fixes from the auditor's findings
   - Show a summary table of changes made:

     | # | Issue | Severity | Fix Applied |
     |---|-------|----------|-------------|
     | 1 | [description] | [severity] | [what was changed] |

   - Inform user that the full report is available in the handoff file
   - Announce completion

#### Path 2: User-guided

1. Spawn `domain-auditor` via the Task tool (same invocation as Path 1)
2. Parse the returned results
3. If **PASS**:
   - Present the auditor's summary to the user
   - Inform user that the full report is available in the handoff file
   - Announce completion
4. If **issues found**:
   - Present findings via `AskUserQuestion` with `multiSelect: true`
   - Each option = one finding: `"[SEVERITY] [description] — Fix: [recommended fix]"`
   - Apply only the fixes the user selected
   - If user selects "Other", follow their custom instructions
   - Show summary table of applied changes
   - Inform user that the full report is available in the handoff file
   - Announce completion

#### Path 3: Skip

- Announce completion
- Note: "You can run the domain auditor manually later with `/domain-auditor <name>`"

### Completion Message

After any path completes, the final message must include:

> Domain "[name]" is ready to use.
