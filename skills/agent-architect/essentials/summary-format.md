# Summary Format

Display this summary at the **start of every response** during agent creation.

## Format Template

```markdown
## Agent Summary: [Agent Name]

**Type:** [Skill | Sub-agent] [with skills: skill1, skill2 | (no skills)]
**Model:** [haiku | sonnet | opus | inherit] - [brief rationale]
**Invocation:** [Manual only | Automatic | User-controlled]
**Domain:** [domain-name] - [brief rationale]

### Definition
- **Persona:** [The X - brief description of character/approach]
- **Mandate:** [One-sentence purpose statement]

### Responsibilities
1. [Primary responsibility]
2. [Secondary responsibility]
...

### Patterns Applied
- [x] [Pattern name] - [why applied]
- [ ] [Pattern name] - [why not applied / N/A]
...

### Tools
- **Allowed:** [tool1, tool2, ...] or "All tools"
- **Disallowed:** [tool1, tool2, ...] or "None"

### Behavioral Constraints
| Constraint | Level | Mechanism | Rationale |
|------------|-------|-----------|-----------|
| [one short sentence] | [1–7] | [exact config that lands in the produced agent — frontmatter line, deny pattern, hook path, AskUserQuestion site, context: fork, positive phrasing, or NEVER clause] | [why this level; why higher levels did not apply] |
...

### Files to Create
| File | Location | Purpose |
|------|----------|---------|
| [filename] | [.claude/path/] | [brief purpose] |
...

### Inter-Agent Communication (if applicable)
- **Receives from:** [agent name] via `[path]`
- **Produces for:** [agent name] via `[path]`
- **Handoff format:** [brief description]

### Test Status (if tested)
- **Last tested:** [iteration count or "Not tested"]
- **Test cases:** [count]
- **Pass rate:** [percentage or "N/A"]
- **Workspace:** [path to workspace]

### Pending Decisions
- [ ] [Question or decision needed]
...

### Recent Changes
- [+] Added: [item]
- [~] Modified: [item]
- [-] Removed: [item] (with user approval)
```

## Rules

### Content Rules

1. **Include EVERYTHING decided** - Every confirmed decision must appear in the summary
2. **Never delete without approval** - Mark items for potential removal, discuss first
3. **Reword for clarity** - Improve user's wording while preserving intent
4. **Use concise language** - Convey ideas briefly but completely
5. **Maintain logical order** - Group related items, prioritize by importance

### Formatting Rules

1. **Use checkboxes** for patterns (checked = applied, unchecked = not applied)
2. **Use tables** for file listings
3. **Use bullet points** for lists
4. **Bold key labels** (Type, Model, etc.)
5. **Keep sections even when empty** - Show "None yet" or "TBD" rather than omitting

### Recent Changes Section

Track what changed in the last response:
- `[+]` for additions
- `[~]` for modifications
- `[-]` for removals (must have user approval)

Remove items from Recent Changes after 2 responses.

## Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| Agent Name | Yes | Kebab-case identifier |
| Type | Yes | Skill or Sub-agent |
| Model | Yes | Recommended model with rationale |
| Invocation | Yes | How the agent is triggered |
| Domain | Yes | Selected knowledge domain |
| Persona | Yes | Character name and approach |
| Mandate | Yes | One-sentence purpose |
| Responsibilities | Yes | Numbered list of duties |
| Patterns Applied | Yes | Checklist of patterns |
| Tools | For sub-agents | Tool access configuration |
| Behavioral Constraints | Yes | Constraint × enforcement level × mechanism × rationale (mechanism column lands in produced agent; rationale stays in summary only) |
| Files to Create | Yes | Complete file listing |
| Inter-Agent Communication | If applicable | Input/output definitions |
| Pending Decisions | Yes | Outstanding questions |
| Test Status | If tested | Last test results summary |
| Recent Changes | Yes | Last response's changes |

## Example Summary

For a complete worked example of an agent summary, see [../references/examples/complete-examples.md](../references/examples/complete-examples.md#summary-format-example).
