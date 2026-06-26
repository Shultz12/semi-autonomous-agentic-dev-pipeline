# Summary Format

Display this summary at the **start of every response** during domain creation, update, or deletion.

## Format Template

```markdown
## Domain Summary: [Domain Name]

**Scope:** [What types of agents/skills does this domain cover]
**Target Agent Types:** [reviewer, developer, orchestrator, etc.]

### Conventions
1. [Convention 1]
2. [Convention 2]
...

### Project Scanning
| Scan | Command | Purpose |
|------|---------|---------|
| [scan name] | [tool command] | [why] |
...

### Tool Recommendations
| Agent Type | Recommended Tools | Rationale |
|------------|-------------------|-----------|
| [type] | [tools] | [why] |
...

### Patterns Designed
| Pattern | Purpose | File |
|---------|---------|------|
| [name] | [brief purpose] | [filename.md] |
...

### Cross-Domain Pattern References
- [Pattern Name] from [domain-name] — [relevance]
...

### Templates
- [template name] — [purpose]
...
(or "None")

### Auditor Checks
| ID | Description | Severity |
|----|-------------|----------|
| [step.Dn] | [what to verify] | [WARNING/ERROR] |
...

**Additional Checklist Count:** [N] checks

### Files to Create/Modify
| File | System | Path | Status |
|------|--------|------|--------|
| [filename] | [Agent Architect/Agent Auditor] | [full path] | [New/Modified] |
...

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

1. **Include EVERYTHING decided** — Every confirmed decision must appear in the summary
2. **Never delete without approval** — Mark items for potential removal, discuss first
3. **Reword for clarity** — Improve user's wording while preserving intent
4. **Use concise language** — Convey ideas briefly but completely
5. **Maintain logical order** — Group related items, prioritize by importance

### Formatting Rules

1. **Use tables** for scanning, tools, patterns, checks, and files
2. **Use numbered lists** for conventions
3. **Bold key labels** (Scope, Target Agent Types, etc.)
4. **Keep sections even when empty** — Show "None yet" or "TBD" rather than omitting

### Recent Changes Section

Track what changed in the last response:
- `[+]` for additions
- `[~]` for modifications
- `[-]` for removals (must have user approval)

Remove items from Recent Changes after 2 responses.

## Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| Domain Name | Yes | Kebab-case identifier |
| Scope | Yes | What types of agents this domain covers |
| Target Agent Types | Yes | Which agent archetypes benefit from this domain |
| Conventions | Yes | Numbered list of domain-specific rules |
| Project Scanning | Yes | Commands to run before designing agents in this domain |
| Tool Recommendations | Yes | Tool access by agent type |
| Patterns Designed | Yes | Domain-specific behavioral patterns |
| Cross-Domain Pattern References | Yes | Relevant patterns from other domains |
| Templates | No | Agent templates for this domain |
| Auditor Checks | Yes | Validation rules for the Agent Auditor |
| Additional Checklist Count | Yes | Total number of domain-specific auditor checks |
| Files to Create/Modify | Yes | Complete file listing with paths |
| Pending Decisions | Yes | Outstanding questions |
| Recent Changes | Yes | Last response's changes |

## Example Summary

For a complete worked example of a domain summary, see [../references/examples/complete-examples.md](../references/examples/complete-examples.md).
