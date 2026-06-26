# Delete Mode

Full deletion workflow. Follow these phases sequentially.

## Phase 1: Target Identification

### If domain name provided in args

(e.g., `/domain-architect delete web-automation`)

1. Check for the domain in both systems:
   - `.claude/skills/agent-architect/domains/<name>/`
   - `.claude/agents/agent-auditor/domains/<name>/`
2. If found → proceed to Phase 2
3. If not found → report error, show available domains from registries

### If no domain name provided

1. List available domains from the current state (injected registries in SKILL.md)
2. Present list via AskUserQuestion: "Which domain would you like to delete?"
3. User selects target

## Phase 2: Impact Analysis

Analyze the full impact of deleting this domain:

### Files to Delete

List every file that will be removed:

```
Files to delete:
- .claude/skills/agent-architect/domains/<domain>/domain.md
- .claude/skills/agent-architect/domains/<domain>/patterns/_index.md
- .claude/skills/agent-architect/domains/<domain>/patterns/<pattern>.md (for each)
- .claude/skills/agent-architect/domains/<domain>/templates/<template>.md (for each)
- .claude/agents/agent-auditor/domains/<domain>/domain.md
```

### Agents Using This Domain

Scan for agents and skills that reference this domain:

1. `Grep "domain: <domain-name>"` in `.claude/agents/` and `.claude/skills/`
2. List each affected agent/skill with its path
3. Warn: "These agents/skills will have an unresolved domain reference after deletion"

### Registry Changes

Show the exact registry entries that will be removed:
- Row to remove from `.claude/skills/agent-architect/domains/_index.md`
- Row to remove from `.claude/agents/agent-auditor/domains/_index.md`
- Lines to remove from `.claude/skills/agent-architect/SKILL.md` Reference Registry section

### Cross-Domain References

Check if other domains reference patterns from the domain being deleted:
1. Grep for the domain name in other domains' `patterns/_index.md` files
2. List any cross-domain references that will break

## Phase 3: Confirmation

**STOP & WAIT** — Present full impact analysis and require explicit confirmation.

Use AskUserQuestion:
- "Are you sure you want to delete the **[domain-name]** domain? This will remove [N] files and affect [M] agents/skills."
- Options: "Delete — I understand the impact" / "Cancel — keep the domain"

If Cancel → announce cancellation and stop.

## Phase 4: Deletion

After user confirms:

1. **Delete all domain files:**
   - Remove Agent Architect domain directory and all contents
   - Remove Agent Auditor domain directory and all contents

2. **Update all 3 registries** using `Edit`:
   - Remove row from Agent Architect `_index.md`
   - Remove row from Agent Auditor `_index.md`
   - Remove domain lines from Agent Architect `SKILL.md` Reference Registry

3. **Report results:**

```
Domain deletion complete.

Deleted:
- .claude/skills/agent-architect/domains/<domain>/ (N files)
- .claude/agents/agent-auditor/domains/<domain>/ (1 file)

Updated:
- .claude/skills/agent-architect/domains/_index.md
- .claude/agents/agent-auditor/domains/_index.md
- .claude/skills/agent-architect/SKILL.md

WARNING: The following agents/skills still reference domain "<domain-name>":
- [list of affected agents]
Consider updating their domain field or assigning a different domain.
```
