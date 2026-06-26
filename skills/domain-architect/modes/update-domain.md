# Update Mode

Full update workflow. Follow these phases sequentially.

## Phase 1: Target Identification

### If domain name provided in args

(e.g., `/domain-architect update dev-tooling`)

1. Check for the domain in both systems:
   - `.claude/skills/agent-architect/domains/<name>/domain.md`
   - `.claude/agents/agent-auditor/domains/<name>/domain.md`
2. If found in at least one → proceed to Phase 2
3. If not found → report error, show available domains from registries

### If no domain name provided

1. List available domains from the current state (injected registries in SKILL.md)
2. Present list via AskUserQuestion: "Which domain would you like to update?"
3. User selects target

## Phase 2: Load State

Read ALL files from both systems to understand the full domain:

1. **Agent Architect files:**
   - Read `.claude/skills/agent-architect/domains/<name>/domain.md`
   - Read `.claude/skills/agent-architect/domains/<name>/patterns/_index.md`
   - Glob `.claude/skills/agent-architect/domains/<name>/patterns/*.md` (excluding `_index.md`)
   - Glob `.claude/skills/agent-architect/domains/<name>/templates/*.md`

2. **Agent Auditor files:**
   - Read `.claude/agents/agent-auditor/domains/<name>/domain.md`

3. **Parse into Domain Summary format:**
   - Extract: name, scope, target agent types
   - Extract: conventions (numbered list)
   - Extract: project scanning table
   - Extract: tool recommendations table
   - Extract: patterns (name, purpose, file)
   - Extract: auditor checks (ID, description, severity)
   - Extract: additional checklist count
   - Build complete file listing
   - Set "Pending Decisions" to empty
   - Set "Recent Changes" to empty

4. **Present loaded summary:**

   > "Here's the current state of the **[domain-name]** domain:"
   >
   > [Full Domain Summary]
   >
   > "What changes would you like to make?"

## Phase 3: Changes

1. **Open-ended first:** Ask what the user wants to change

2. **Targeted follow-ups:** Based on response, ask specific questions about:
   - Conventions to add, modify, or remove
   - Patterns to add, modify, or remove
   - Auditor checks to add, modify, or remove
   - Scanning instructions to update
   - Tool recommendations to update

3. **Track changes in summary:**
   - `[+] Added:` for new items
   - `[~] Modified:` for changes to existing items
   - `[-] Removed:` for deletions (require explicit user approval first)

4. **Scope awareness table** — maintain and show:

   | File | Location | Change Type | Description |
   |------|----------|-------------|-------------|
   | [filename] | [system] | Modified/New/Deleted | [what changes] |

5. **Domain scope changes:** If the update changes the domain's fundamental scope, flag this to the user — it may affect agents already using this domain

6. **Impact analysis:** If a change cascades (e.g., removing a convention → remove matching auditor check, adding a pattern → update `_index.md`), identify and note all impacts

## Phase 4: Research (If Needed)

If the user wants to add **new** conventions or patterns, trigger structured research:

1. Derive search queries from the new content being added (same categories as create mode)
2. Execute searches using `WebSearch`, deep-dive with `WebFetch`
3. Present findings for user confirmation
4. Only runs when new domain knowledge is being added, not for structural changes

If no new domain knowledge is being added, skip to Phase 5.

## Phase 5: Refinement

Continue conversation until all pending decisions are resolved:
- Show updated summary every response (with Recent Changes tracking)
- Acknowledge changes made
- Ask clarifying questions OR suggest proceeding

### Cross-Domain Pattern Discovery (If New Patterns Added)

If new patterns were added during this update:
1. Check if new patterns are relevant as cross-references for other domains
2. Check if patterns from other domains are relevant to the updated domain
3. Present findings for user confirmation

When all changes captured and no pending decisions remain → suggest proceeding.

## Phase 6: Validation & Application

### Validation

Run standard checklist PLUS update-specific checks:
- [ ] No unintended changes to files outside the domain's directories
- [ ] All existing functionality preserved unless explicitly changed
- [ ] Convention numbering is sequential after changes
- [ ] Auditor check IDs are sequential after changes
- [ ] Additional checklist count updated if checks added/removed
- [ ] Registry updates needed only if domain scope/description changed

### File Preview

Show COMPLETE file contents for ALL modified and new files:

```
**File 1 of N: .claude/skills/agent-architect/domains/<domain>/domain.md (Modified)**

---
[complete file contents]
---

**File 2 of N: .claude/agents/agent-auditor/domains/<domain>/domain.md (Modified)**

---
[complete file contents]
---

...

[Registry updates only if domain scope/description changed]

---

Please review the files above. Reply with:
- "Update" to proceed with changes
- Specific feedback to make adjustments
```

### Approval & Write

- Wait for explicit approval
- Use `Write` for new files, `Edit` for modifications to existing files
- Report each file created/updated
- Do **not** announce completion — proceed to Phase 7

## Phase 7: Review & Completion

See [shared-techniques.md > Review Integration](../essentials/shared-techniques.md#review-integration) for the full workflow:

1. Present review options to user (Autonomous / User-guided / Skip)
2. If approved: spawn `domain-auditor` via Task tool
3. Handle results (apply fixes if issues found, or announce clean pass)
4. Announce completion: `Domain "<name>" is ready to use.`
