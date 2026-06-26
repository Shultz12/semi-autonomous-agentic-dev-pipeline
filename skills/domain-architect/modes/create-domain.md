# Create Mode

Full domain creation workflow. Follow these phases sequentially.

## Phase 1: Discovery

### Opening

Start every creation conversation with:

```
I'm the Domain Architect. I'll help you design and build a domain knowledge pack for the Agent Architect and Agent Auditor systems.

Let's start with the basics:
1. **What should we name this domain?** (kebab-case, e.g., "web-automation", "data-pipeline")
2. **What types of agents/skills does this domain cover?** (describe the scope)
3. **What agent archetypes benefit most?** (reviewer, developer, orchestrator, interactive, etc.)

As we progress, I'll ask more specific questions and show you a running summary of what we're building.
```

### Progressive Questions

Ask questions in order of dependency. Don't ask everything at once.

**Tier 1 — Core Identity (ask first)**
1. Domain name (kebab-case)
2. Scope — what types of agents/skills does this domain cover?
3. Target agent types (reviewer, developer, orchestrator, interactive, etc.)

### Scope Overlap Detection

After gathering Tier 1 answers, **immediately check for overlap** against existing domains:

1. The current state (from `!`command`` injection in SKILL.md) already shows existing domains
2. Compare proposed scope against each existing domain's scope description
3. If overlap detected, present to user:
   - Show the overlapping scope points
   - Use AskUserQuestion with options:
     - "Narrow scope to avoid overlap"
     - "This is intentional specialization — proceed"
     - "Merge into existing domain instead" (→ switch to Update mode)
4. If no overlap, proceed to Phase 2

## Phase 2: Research

After Discovery provides enough context, conduct targeted web research to ground the domain in industry best practices.

### Structured Query Derivation

Derive search queries by category based on the domain's scope:

| Category | Query Pattern | Purpose |
|----------|---------------|---------|
| Conventions | "[domain subject] conventions best practices" | Discover industry-standard rules |
| Patterns | "[domain subject] design patterns common pitfalls" | Find reusable behavioral patterns |
| Validation | "[domain subject] linting rules validation criteria" | Find what should be checked |
| Tool ecosystem | "[domain subject] tools frameworks libraries" | Understand the technical landscape |

### Execution

1. Execute searches using `WebSearch` for each category
2. Deep-dive with `WebFetch` on promising results
3. Synthesize findings organized by category:
   - Each finding: convention/pattern discovered, source link, relevance to domain
   - Recommendation per finding: "incorporate" / "skip" / "needs discussion"

### User Confirmation

Present findings to user for selection before proceeding:
- User selects which findings to incorporate
- Discuss any "needs discussion" items
- Record incorporated findings in the summary

## Phase 3: Design

Design the Agent Architect domain files. Read [references/domain-structure.md](../references/domain-structure.md) before starting this phase for file templates and specificity guidance.

### Conventions Design

Each convention must be **specific, actionable, and verifiable** — could an auditor write a pass/fail rule for it?

Present drafted conventions to user with GOOD vs BAD examples:

```
GOOD: "All API endpoints must include rate-limiting middleware"
BAD:  "APIs should be well-designed"

GOOD: "File names use kebab-case with .handler.ts suffix"
BAD:  "Use good naming conventions"
```

Draft conventions for user approval before finalizing.

### Project Scanning Design

Design the scanning instructions agents should run before working in this domain:

- Required scans (must always run)
- Optional scans (run conditionally)

Each scan: name, tool command, purpose.

### Tool Recommendations

Design tool access recommendations by agent type. Follow the principle of minimum necessary access.

### Pattern Design (Always Interactive)

For each pattern:
1. Propose a pattern name and purpose
2. Discuss when it should be applied
3. Draft implementation guidance
4. Explain rationale
5. Ask: "Add another pattern, or is the pattern set complete?"

Patterns are always designed interactively — no scaffold-only option.

### Cross-Domain Pattern Discovery

After patterns are designed, discover relevant patterns from other domains:

1. Read each existing domain's `patterns/_index.md` from `.claude/skills/agent-architect/domains/`
2. Assess each existing pattern's relevance to the new domain's scope
3. Present relevant patterns to user as cross-domain references
4. User selects which to include in the Cross-Domain Patterns section of `patterns/_index.md`

### Templates Design (If Applicable)

If the domain warrants agent templates:
1. Identify common agent structures in this domain
2. Design templates with YAML frontmatter + markdown structure
3. Present for user approval

If no templates are needed, note "None" in the summary.

## Phase 4: Auditor Design

Design the Agent Auditor domain file. Read [references/domain-structure.md](../references/domain-structure.md) if not already loaded.

### Deriving Checks from Conventions

For each convention designed in Phase 3, ask:
- "Should the auditor validate this? (Yes / No / Already covered by base checks)"

For each "Yes":
1. Design the check together with the user:
   - **ID**: `<step>.D<n>` format (step = base auditor step it extends, n = sequential)
   - **What to verify**: Concrete inspection criteria
   - **Pass/Fail criteria**: Unambiguous, not subjective
   - **Severity**: WARNING or ERROR
2. Present the check for user approval

```
GOOD check: "Verify all file paths use forward slashes, not backslashes"
  Pass: No backslash characters found in path strings
  Fail [WARNING]: Backslash found in file path

BAD check: "Check that code quality is good"
  (Not verifiable — what counts as "good"?)
```

### Calculate Checklist Count

Count the total number of domain-specific checks for the `Additional Checklist Count` field.

## Phase 5: Refinement

Continue conversation until all pending decisions are resolved:
- Show updated summary every response (with Recent Changes tracking)
- Acknowledge changes made
- Ask clarifying questions OR suggest proceeding
- Resolve any remaining "TBD" or "None yet" fields

When all decisions are captured and no pending decisions remain → suggest proceeding to validation.

## Phase 6: Validation & Creation

### Pre-Creation Validation

Run these checks and report results:

```
**Validation Results:**

Naming:
- [ ] Domain name follows kebab-case
- [ ] No duplicate in Agent Architect registry
- [ ] No duplicate in Agent Auditor registry

Scope:
- [ ] Scope overlap check passed
- [ ] Scope is specific enough to be useful

Content Quality:
- [ ] All conventions are specific, actionable, verifiable
- [ ] All auditor checks have concrete pass/fail criteria
- [ ] Check IDs follow <step>.D<n> format

Completeness:
- [ ] Agent Architect domain.md complete
- [ ] Agent Architect patterns/_index.md complete
- [ ] Agent Auditor domain.md complete
- [ ] Registry updates prepared for all 3 registries

Paths:
- [ ] All file paths use forward slashes
```

### File Preview

Show ALL files with complete contents:

```
**File 1 of N: .claude/skills/agent-architect/domains/<domain>/domain.md (New)**

---
[complete file contents]
---

**File 2 of N: .claude/skills/agent-architect/domains/<domain>/patterns/_index.md (New)**

---
[complete file contents]
---

...

**Registry Update 1 of 3: .claude/skills/agent-architect/domains/_index.md**

[Show the exact Edit: old_string → new_string for the table addition]

**Registry Update 2 of 3: .claude/agents/agent-auditor/domains/_index.md**

[Show the exact Edit: old_string → new_string for the table addition]

**Registry Update 3 of 3: .claude/skills/agent-architect/SKILL.md**

[Show the exact Edit: old_string → new_string for Reference Registry addition]

---

Please review the files above. Reply with:
- "Create" to proceed with file creation
- Specific feedback to make changes
```

### Creation

After user approves:
1. Write all new domain files using `Write`
2. Update all 3 registries using `Edit`
3. Report each file created/updated

```
Creating domain files...

Created: .claude/skills/agent-architect/domains/<domain>/domain.md
Created: .claude/skills/agent-architect/domains/<domain>/patterns/_index.md
Created: .claude/agents/agent-auditor/domains/<domain>/domain.md
Updated: .claude/skills/agent-architect/domains/_index.md
Updated: .claude/agents/agent-auditor/domains/_index.md
Updated: .claude/skills/agent-architect/SKILL.md
```

Do **not** announce completion. Proceed to Phase 7.

## Phase 7: Review & Completion

See [shared-techniques.md > Review Integration](../essentials/shared-techniques.md#review-integration) for the full workflow:

1. Present review options to user (Autonomous / User-guided / Skip)
2. If approved: spawn `domain-auditor` via Task tool
3. Handle results (apply fixes if issues found, or announce clean pass)
4. Announce completion: `Domain "<name>" is ready to use.`
