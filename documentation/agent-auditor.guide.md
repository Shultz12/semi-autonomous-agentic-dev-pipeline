# Agent Auditor - User Guide

## What It Does

The Agent Auditor validates agent and skill definitions before they're created. Think of it as a quality control inspector that checks your agent designs against established standards and best practices.

**Key Points:**
- It's **advisory only** - it reports findings but cannot block creation
- It checks **71 base validation criteria (sub-agent) or 68 (skill)** across 10 categories, plus domain-specific checks
- It's **domain-aware** - detects the agent's domain and applies specialized validation rules
- It detects **potential duplicates** with existing agents/skills at both personal and project levels
- The final decision to proceed always rests with you

---

## Audit Posture

The auditor adopts a strict, by-the-book posture by design. It defaults to doubt: every claim an agent file makes — "applies pattern X", "follows contract Y", "never does Z" — is treated as suspect until the workflow text, frontmatter, or cited file has been checked against the relevant rule. A PASS verdict is earned by coverage — every loaded rule × every file in the artifact — not by sampling a few categories. File paths and cross-references are verified with Read or Glob before being trusted, and severities are applied as the standards file specifies them rather than inflated or invented. This is balanced by a Self-Check pass that drops LOW-confidence findings (those not directly backed by file:line evidence) before the report is written: rigor here means thorough coverage, not fabricated issues or inflated severities.

Every CRITICAL and ERROR finding carries a Confidence value (HIGH or MEDIUM) alongside its Severity:
- **HIGH** — direct `file:line` evidence from the reviewed artifact demonstrates the defect (missing frontmatter field, absent workflow section, Glob returned no matches for a cited path).
- **MEDIUM** — structural pattern mismatch across the artifact's files (e.g., sibling constraints carry rationale while this one does not; contract documents a field the workflow never populates).

LOW-confidence findings are never reported — they are re-investigated once and either lifted to MEDIUM/HIGH with stronger evidence, or dropped.

---

## When It's Used

The reviewer is typically called by the Agent Architect after you've designed a new agent or skill and given permission to review it. You might also invoke it directly to validate an existing agent definition.

**Common scenarios:**
- Before creating a new sub-agent
- Before creating a new skill
- When auditing existing agent definitions
- When troubleshooting why an agent isn't working as expected

---

## What It Checks

### 1. Structural Validation (6 checks)
- Name follows kebab-case format (`my-agent`, not `MyAgent`)
- Files are in the correct location
- YAML frontmatter is valid
- Paths use forward slashes

### 2. Frontmatter Fields (4-8 checks)
- Required fields present (`name`, `description`)
- Optional fields have valid values (`model`, `permissionMode`, `tools`)
- Type-specific fields validated (skills have different requirements than sub-agents)

### 3. Description Quality (5 checks)
- Written in third person ("Reviews code..." not "I review code...")
- Explains WHAT the agent does
- Explains WHEN to use it
- Contains keywords for discovery
- Specific enough to differentiate from other agents

### 4. Content Sections (9 checks sub-agent, 2 skill)
- Required sections present (Persona, Mandate, Constraints, Responsibilities, Workflow)
- Conditional sections present when needed (Output Format, Verification Protocol)

### 5. Tool Validation (5 checks)
- Tools match the agent's stated purpose
- Red flags detected (e.g., read-only reviewer with write tools)
- Permission mode aligns with tool risk level

### 6. Pattern Validation (6 checks + domain-specific)
- Appropriate behavioral patterns for agent type
- Required patterns are implemented (e.g., reviewers need "Tool Execution Verification")
- Pattern implementation markers present in content
- Constraint Enforcement Hierarchy compliance (prose constraints not used where architectural mechanisms — tool restriction, deny rules, hooks, AskUserQuestion, context isolation — were available)
- **Domain-specific checks** applied when a domain is detected (see "Domain-Aware Validation" below)

### 7. Coherence Checks (8 checks)
- Purpose aligns with tools, model, and patterns
- No internal contradictions
- Scans for duplication with existing agents/skills
- Output persistence — agents that write project-level files commit them via a self-commit step (referencing `commit-to-git`); user-level-only writers are exempt

### 8. Content Hygiene (14 checks)
- No cross-file redundancy (same information in multiple files)
- No instructions for entities outside the agent's control
- No prose duplicating what frontmatter already enforces
- No self-referential file listings that duplicate workflow
- No vague instructions where specific bounded equivalents exist
- No copy-pasted content with trivial field changes
- No contradictory authority claims across files
- No references to other agents' internal files
- No orphaned references (broken file/section links)
- No redundant indirection (pointers to content already in context)
- No cross-boundary role references (scope defined by exclusion of other agents)
- Emphasis calibration (NEVER/ALWAYS/MUST reserved for genuine safety constraints)
- Constraint rationale (every constraint explains why it exists)
- Rationale discipline (judgment rationale compressed to one line; maintainer rationale absent)

### 9. Contract & Guide Validation (10 checks)
- Interface contract exists (for agents with inter-agent communication)
- Required sections present (Input, Output, Guarantees)
- Input spec matches agent's actual capabilities (field-by-field comparison)
- Output spec matches agent's actual output (field-by-field, including written files)
- No internal implementation details exposed
- Language and format quality (imperative voice, examples)
- All invocation modes documented
- Guide exists (checked at both `.claude/documentation/` and `.claude/documentation/`)
- Guide has required sections ("What It Does" and "Related")
- Guide content accuracy (numeric counts, file trees, behavioral descriptions match agent's current state)

---

## Domain-Aware Validation

The auditor detects the `domain` field from an agent's YAML frontmatter and loads domain-specific validation rules.

### Available Domains

| Domain | What It Checks |
|--------|----------------|
| `dev-tooling` | Internal file organization, pipeline I/O conventions, feedback loop implementation, progressive question flow, output enforcement, self-criticism, severity+confidence pairing, escalation routing, savepoint & revert (9 checks) |
| `web-automation` | Rate limiting, error recovery, structured output validation, no hardcoded credentials, robots.txt compliance (5 checks) |
| `agent-tooling` | Internal file organization, summary format, mode routing logic, worked examples, contrastive examples, review integration, central standards file, dual-output protocol, step-based workflow, interface contracts, self-verification loop, registry update instructions (12 checks) |

### How It Works

1. The auditor reads the `domain` field from frontmatter
2. If the domain is known, it loads the domain's validation rules
3. Domain checks run after behavioral pattern checks (step 7)
4. Domain findings are included in the report with step-number-prefixed IDs (e.g., `1.D1`, `5.D1`, `7.D1`, `9.D1`) indicating which base validation category each domain check extends

### What If No Domain Is Specified?

- A WARNING is noted but validation continues
- Domain-specific checks are skipped (reported as N/A)
- All base checks still run normally

### Adding New Domains

New domains can be added by creating a `domains/<domain-name>/domain.md` file in the agent-auditor directory and registering it in `domains/_index.md`.

---

## Understanding the Report

### Overall Status

| Status | Meaning |
|--------|---------|
| **PASS** | No critical or error-level issues found |
| **WARNINGS** | Functional but has areas for improvement |
| **ISSUES FOUND** | Has critical or error-level issues that should be fixed |

### Severity Levels

| Severity | What It Means | Action |
|----------|---------------|--------|
| **CRITICAL** | Agent won't function correctly | Must fix before creation |
| **ERROR** | Violates standards, may cause issues | Should fix |
| **WARNING** | Suboptimal but will work | Consider fixing |
| **INFO** | Suggestion for improvement | Optional |

### Sample Report Structure

```
## Agent Review Report

**Agent:** my-new-agent
**Type:** Sub-agent
**Overall Status:** WARNINGS

### Severity Summary
| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| ERROR | 0 |
| WARNING | 2 |
| INFO | 1 |

### Compliance Summary
| Category | Status | Issues |
|----------|--------|--------|
| Structural (6) | Pass | 0 |
| Description (5) | Fail | 1 |
...

### Recommendations
| Priority | Issue | Recommendation |
|----------|-------|----------------|
| MEDIUM | Missing WHEN component | Add "Use when..." to description |
...
```

---

## How It Works Internally

The reviewer follows a 12-step validation process:

```
Steps 1-10:  Execute specific validation checks
Step 11:     Compile findings into structured summary
Step 12:     Verify all checks (71 base for sub-agents, 68 for skills, + domain) are documented
             - If missing, execute directly and add to summary
             - Repeat until complete
```

This self-correcting loop ensures comprehensive coverage even if individual steps miss something.

---

## Tips for Passing Review

### Quick Wins
1. Use kebab-case for names: `code-reviewer` not `CodeReviewer`
2. Write descriptions in third person: "Reviews..." not "I review..."
3. Include "Use when..." in your description
4. Match tools to purpose (reviewers shouldn't have Edit/Write)

### Common Issues

| Issue | Fix |
|-------|-----|
| "First person voice detected" | Change "I will..." to "Validates..." |
| "Missing WHEN component" | Add "Use when..." or "Use for..." |
| "Read-only purpose but has Write tools" | Remove Write/Edit from tools list |
| "Missing Verification Protocol" | Add section for reviewer/validator agents |
| "Potential overlap with [agent]" | Ensure clear differentiation or consider extending existing agent |

---

## Limitations

- **Advisory only**: Cannot prevent agent creation
- **No subjective judgments**: Doesn't evaluate whether your agent idea is "good"
- **Pattern detection is heuristic**: May miss custom pattern implementations
- **Duplication check is keyword-based**: May flag false positives

---

## Related Files

The reviewer's validation logic is defined in:
```
.claude/agents/agent-auditor/
├── agent-auditor.md            # Main agent definition
├── essentials/
│   ├── agent-standards.md      # All validation criteria
│   └── pipeline-conformance.md # Pipeline participation role-gated checks
├── examples/
│   └── sample-review.md        # Reference report format
├── steps/                      # Step-by-step validation logic
│   ├── 01-structural.md
│   ├── 02-core-frontmatter.md
│   ├── ...
│   ├── 10-contract-validation.md
│   ├── 11-create-summary.md
│   └── 12-verify-checklist.md
└── domains/                    # Domain-specific validation rules
    ├── _index.md               # Domain registry
    ├── dev-tooling/domain.md   # Dev-tooling checks (9)
    ├── web-automation/domain.md # Web-automation checks (5)
    └── agent-tooling/domain.md # Agent-tooling checks (12)
```

Supporting files:
- `.claude/agents/interface-contracts/agent-auditor.contract.md` - Interface contract
- `.claude/documentation/agent-auditor.guide.md` - This guide

You don't need to read the agent files - they're for the AI. This guide covers everything you need to know as a user.
