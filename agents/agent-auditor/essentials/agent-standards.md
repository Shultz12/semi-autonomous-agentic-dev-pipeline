# Agent Standards

Comprehensive validation criteria for reviewing agent and skill definitions.

## 1. Severity Definitions

| Severity | Code | Definition | Action Required |
|----------|------|------------|-----------------|
| **CRITICAL** | `[CRITICAL]` | Prevents artifact from functioning correctly | Must fix before creation |
| **ERROR** | `[ERROR]` | Violates standards, may cause issues | Should fix |
| **WARNING** | `[WARNING]` | Suboptimal but functional | Consider fixing |
| **INFO** | `[INFO]` | Suggestion for improvement | Optional |

**Overall Status Determination:**
- **PASS**: No CRITICAL or ERROR issues
- **WARNINGS**: No CRITICAL/ERROR but has WARNING issues
- **ISSUES FOUND**: Has CRITICAL or ERROR issues

---

## 2. Structural Rules

### 2.1 Naming Conventions

| Rule | Requirement | Severity |
|------|-------------|----------|
| Format | kebab-case (lowercase + hyphens only) | CRITICAL |
| Pattern | `^[a-z][a-z0-9]*(-[a-z0-9]+)*$` | CRITICAL |
| Invalid | `PascalCase`, `snake_case`, `UPPERCASE`, spaces | CRITICAL |
| Skill max length | 64 characters | ERROR |

### 2.2 File Locations

| Artifact Type | Location Pattern | File Name |
|---------------|------------------|-----------|
| Sub-agent | `.claude/agents/<name>/` | `<name>.md` |
| Skill | `.claude/skills/<agent>/<skill>/` | `SKILL.md` (exact, case-sensitive) |

### 2.3 Path and Size Rules

| Rule | Requirement | Severity |
|------|-------------|----------|
| Path separators | Forward slashes only (`/`) | ERROR |
| Windows backslashes | Never allowed (`\`) | ERROR |
| Empty folders | Not allowed | WARNING |

---

## 3. Sub-agent Frontmatter Requirements

### 3.1 Required Fields

| Field | Required | Validation | Severity if Invalid |
|-------|----------|------------|---------------------|
| `name` | Yes | Must match folder and file name | CRITICAL |
| `description` | Yes | Non-empty string | CRITICAL |

### 3.2 Optional Fields

| Field | Format | Valid Values | Severity if Invalid |
|-------|--------|--------------|---------------------|
| `tools` | Comma-separated | Agent, AskUserQuestion, Bash, Edit, Glob, Grep, LSP, NotebookEdit, Read, Skill, WebFetch, WebSearch, Write, TaskCreate, TaskGet, TaskList, TaskUpdate, TodoWrite, plus MCP tool names | ERROR |
| `model` | String | `haiku`, `sonnet`, `opus`, `inherit` | ERROR |
| `permissionMode` | String | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan` | ERROR |
| `disallowedTools` | Comma-separated | Same as tools list | ERROR |

### 3.3 Domain Field

| Field | Format | Valid Values | Severity if Invalid |
|-------|--------|--------------|---------------------|
| `domain` | String | Known domain name (e.g., `dev-tooling`, `web-automation`) | WARNING if missing, WARNING if unknown value |

### 3.4 Field Conflicts

| Conflict | Severity |
|----------|----------|
| Same tool in both `tools` and `disallowedTools` | ERROR |

---

## 4. Skill Frontmatter Requirements

### 4.0 Domain Field

| Field | Format | Valid Values | Severity if Invalid |
|-------|--------|--------------|---------------------|
| `domain` | String | Known domain name (e.g., `dev-tooling`, `web-automation`) | WARNING if missing, WARNING if unknown value |

### 4.1 Required Fields

| Field | Required | Validation | Severity if Invalid |
|-------|----------|------------|---------------------|
| `name` | Yes | Must match skill folder name, max 64 chars | CRITICAL |
| `description` | Yes | Non-empty string | CRITICAL |

### 4.2 Optional Fields

| Field | Format | Valid Values | Severity if Invalid |
|-------|--------|--------------|---------------------|
| `allowed-tools` | Comma-separated | Valid tool names | ERROR |
| `context` | String | `fork` | ERROR |
| `agent` | String | `Explore`, `Plan`, `general-purpose` (required if context:fork) | CRITICAL |
| `user-invocable` | Boolean | `true`, `false` | ERROR |
| `disable-model-invocation` | Boolean | `true`, `false` | ERROR |
| `argument-hint` | String | Non-empty if present | WARNING |
| `hooks` | Object | Valid hook structure | ERROR |

---

## 5. Description Quality Criteria

### 5.1 Voice Requirements

| Requirement | Indicators of Pass | Indicators of Fail | Severity |
|-------------|-------------------|-------------------|----------|
| Third person | "Reviews...", "Creates...", "Validates..." | "I review...", "My purpose...", "We will..." | ERROR |

### 5.2 Content Components

| Component | What to Check | Severity if Missing |
|-----------|---------------|---------------------|
| **WHAT** | Action verbs describing capabilities | ERROR |
| **WHEN** | Usage triggers: "Use when...", "Use for...", "Call when..." | WARNING |
| **Trigger keywords** | Domain terms, technology names, action words | WARNING |
| **Specificity** | Differentiates from other agents | WARNING |

### 5.3 Good vs Bad Examples

**Good:**
> "Reviews code changes for security vulnerabilities, architectural compliance, and test coverage. Use when code has been modified or before merging pull requests."

**Bad:**
> "Helps with code" (vague, no triggers)
> "I review code for you" (wrong person)
> "Code reviewer" (not a sentence)

---

## 6. Content Section Requirements

### 6.1 Sub-agent Required Sections

| Section | Expected Content | Severity if Missing |
|---------|------------------|---------------------|
| **Persona** | H1 header establishing identity | ERROR |
| **Mandate** | Paragraph describing core purpose | ERROR |
| **Core Constraints** | Structured constraints with prohibitions and behavioral guidelines (e.g., "Never Do"/"Always Do" or "Safety Boundaries"/"Operating Principles") | ERROR |
| **Responsibilities** | Numbered list of duties | ERROR |
| **Workflow** | Phased approach with clear steps | ERROR |

### 6.2 Conditional Sections

| Section | Required When | Severity if Missing |
|---------|---------------|---------------------|
| **Output Format** | Agent produces structured output (reports, templates) | WARNING |
| **Codebase References** | Agent consults specific files | INFO |
| **Inter-Agent Communication** | Agent spawns or hands off to other agents | WARNING |
| **Verification Protocol** | Agent is reviewer/validator type | ERROR |

### 6.3 Skill Required Sections

| Section | Expected Content | Severity if Missing |
|---------|------------------|---------------------|
| **Title** | H1 header | ERROR |
| **Introduction** | Brief purpose explanation | WARNING |

---

## 7. Tool Restriction Rules

### 7.1 Purpose-Tool Alignment

| Purpose Keywords | Expected Tools |
|------------------|----------------|
| review, validate, check, analyze, audit | Read, Grep, Glob |
| create, implement, build, fix, write, develop | Read, Edit, Write, Bash, Grep, Glob |
| explore, research, search, find, discover | Read, Grep, Glob, WebSearch, WebFetch |
| coordinate, orchestrate, manage, pipeline | Agent, Read + purpose-specific |
| plan, design, architect | Read, Grep, Glob (plan mode) |

### 7.2 Red Flags

| Condition | Issue | Severity |
|-----------|-------|----------|
| Read-only purpose + Write/Edit tools | Tool mismatch | ERROR |
| Advisory purpose + Agent tool | Can spawn sub-agents unexpectedly | WARNING |
| Reviewer + Bash without justification | Unjustified access | WARNING |
| Plan mode + Write/Edit tools | Mode conflict | ERROR |
| Full access without justification | Over-permissioned | WARNING |

### 7.3 Permission Mode Alignment

| Permission Mode | Appropriate For | Risk Level |
|-----------------|-----------------|------------|
| `plan` | Read-only exploration | Lowest |
| `default` | Standard operations | Low |
| `acceptEdits` | Trusted code modifications | Medium |
| `dontAsk` | Auto-deny (allowed tools work) | Medium |
| `bypassPermissions` | Highly trusted automation | Highest |

---

## 8. Model Selection Criteria

### 8.1 Task-Model Mapping

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| Simple, repetitive | `haiku` | Fast, cost-effective |
| Standard tasks | `sonnet` | Balanced (default) |
| Complex reasoning, architecture | `opus` | Deep analysis |
| Match caller context | `inherit` | Consistency |

### 8.2 Justification Requirements

| Model Selected | Justification Needed | Severity if Unjustified |
|----------------|---------------------|-------------------------|
| `haiku` | Agent performs simple, repetitive tasks | WARNING |
| `sonnet` | None (default) | N/A |
| `opus` | Agent makes complex architectural decisions | WARNING |
| `inherit` | Agent should match calling context | N/A |

---

## 9. Pattern Requirements

### 9.1 Patterns by Agent Type

| Agent Type | Required Patterns |
|------------|-------------------|
| Reviewer | Tool Execution Verification, Loop Guards |
| Developer | Search Before Code, Loop Guards |
| Planner | Pre-Computational Logic |
| Pipeline/Orchestrator | Handoff Protocol |
| Validator | Defense-in-Depth, Tool Execution Verification |

**Cross-domain applicability:** Some domain-specific patterns are relevant beyond their defining domain. For example, dev-tooling's Feedback Loop applies to any iterative agent regardless of domain, and Loop Guards (a base pattern above) is recommended by agent-tooling for its auditor agents. Base patterns are always checked by agent type. Domain-specific operational patterns are checked only when the artifact's `domain` field matches.

### 9.2 Pattern Implementation Markers

| Pattern | Must Contain | Location |
|---------|--------------|----------|
| **Loop Guards** | Max attempts number, escalation procedure | Workflow/Constraints |
| **Tool Execution Verification** | "Verification Protocol" section, trust protocol | Dedicated section |
| **Search Before Code** | Search/find step before implementation | Workflow |
| **Handoff Protocol** | Inter-Agent Communication section, handoff format | Dedicated section |
| **Defense-in-Depth** | Multiple validation layers | Workflow |
| **Pre-Computational Logic** | Validation before generating output | Workflow |

**Note:** The patterns listed above are **behavioral patterns** — universal safety and workflow patterns applicable regardless of domain. Domain-specific **operational patterns** and **convention checks** are defined in `domains/<domain>/domain.md` and validated by step 7 when a domain is detected in the artifact's frontmatter.

### 9.3 Pattern File Completeness

| Rule | Requirement | Severity |
|------|-------------|----------|
| Required sections | Pattern files must contain: Purpose, When to Apply, Implementation, Rationale, Example | INFO |
| Scope | Only applies to agents that have pattern files in `patterns/` directories | INFO |

### 9.4 Pattern Definitions

| Pattern | Purpose |
|---------|---------|
| Search Before Code | Find existing patterns before creating new |
| Loop Guards | Prevent infinite iteration loops |
| Pre-Computational Logic | Validate assumptions before generating output |
| Tool Execution Verification | Back claims with actual tool output |
| Defense-in-Depth | Validate across multiple layers |
| Handoff Protocol | File-based inter-agent communication |

### 9.5 Constraint Enforcement Hierarchy

| Rule | Requirement | Severity |
|------|-------------|----------|
| Hierarchy compliance | Prose constraints (levels 6–7) must not encode behaviors that levels 1–5 (tool restriction, permissions deny, PreToolUse/PostToolUse hooks, AskUserQuestion, context isolation) could enforce architecturally | WARNING |
| Acceptable at prose level | Judgment calls, stylistic posture, framing rules, and reinforcement of architecturally-enforced rules (defense-in-depth) | — |
| Reference | The seven-level rubric is defined in agent-architect's `references/best-practices.md` → Constraint Enforcement Hierarchy | — |

---

## 10. Semantic Coherence Rules

### 10.1 Cross-Validation Requirements

| Validation | What to Check | Severity if Inconsistent |
|------------|---------------|--------------------------|
| Purpose-Tools | Tools support stated purpose | ERROR |
| Purpose-Model | Model appropriate for complexity | WARNING |
| Purpose-Patterns | Patterns match agent type | WARNING |
| Internal Consistency | No self-contradictions | ERROR |

### 10.2 Common Inconsistencies

| Inconsistency | Example |
|---------------|---------|
| Purpose contradicts tools | "Read-only reviewer" with Edit tool |
| Constraint contradicts responsibility | "Never modify" + "Fix issues" |
| Model doesn't match complexity | Simple task with opus |
| Missing required pattern | Reviewer without verification protocol |

### 10.3 Reference-Instruction Consistency

| Rule | Requirement | Severity |
|------|-------------|----------|
| Self-consistency | Agent's own instructions must follow principles stated in its reference files | WARNING |
| Heuristic checks | Apply known pattern checks (see table below) | WARNING |

**Heuristic Pattern Table:**

| Reference Principle | Check Against Core Definition |
|---------------------|-------------------------------|
| "calibrate emphasis" / "reserve MUST/NEVER for safety" | Count NEVER/ALWAYS/MUST in constraints; if >3, verify each is a genuine safety constraint |
| "explain the why" / "include rationale" | Check whether constraints have accompanying rationale |
| "progressive disclosure" | Check whether all instructions are front-loaded vs distributed |
| "right altitude" / "balance specificity and flexibility" | Check whether rules are overly rigid for non-critical concerns |

### 10.4 Output Persistence (Self-Commit)

| Rule | Requirement | Severity |
|------|-------------|----------|
| Project writers commit | An artifact whose workflow writes files into the project repository must include a final-step instruction to commit them via the `commit-to-git` skill, referenced through progressive disclosure (subagent Reads it at the commit step; skill invokes it via the Skill tool) — not preloaded via `skills:` frontmatter | WARNING |
| User-level writers exempt | An artifact that writes only under `.claude/` or produces no files needs no commit step — report N/A | — |
| Pipeline overlap | When the artifact is a pipeline participant that embodies Role A (committer), commit behavior is validated by Pipeline Conformance (`PC.A1`); record this coherence check as deferred to avoid double-counting | — |

---

## 11. Duplication Detection

### 11.1 Scan Targets

| Location | Pattern |
|----------|---------|
| Personal-level agents | `.claude/agents/**/*.md` |
| Personal-level skills | `.claude/skills/**/SKILL.md` |
| Project-level agents | `.claude/agents/**/*.md` |
| Project-level skills | `.claude/skills/**/SKILL.md` |

Scan both personal (`.claude/`) and project (`.claude/`) levels for comprehensive duplication detection.

### 11.2 Overlap Assessment

**Significant Overlap (WARNING):**
- Same primary purpose
- Same target domain
- Similar trigger keywords
- Would be chosen for same user requests

**Acceptable Differentiation:**
- Different scope (subset relationship)
- Different approach (same goal, different method)
- Different specialization (same domain, different focus)

---

## 12. Content Hygiene Rules

### 12.1 Cross-File Redundancy

| Rule | Requirement | Severity |
|------|-------------|----------|
| No duplication | Each piece of information must exist in exactly one file within the agent | WARNING |
| Tolerance | Minor overlap in introductory context is acceptable; verbatim repeated paragraphs are not | WARNING |

### 12.2 Information Agent Can't Act On

| Rule | Requirement | Severity |
|------|-------------|----------|
| Actionable scope | All instructions must be actionable by this agent, not by callers, users, or downstream systems | WARNING |
| Boundary | Instructions like "the calling agent should..." or "the user must..." belong in contracts or documentation, not agent files | WARNING |

### 12.3 System-Enforced Constraints

| Rule | Requirement | Severity |
|------|-------------|----------|
| No prose duplication | Do not restate in prose what frontmatter fields already enforce | WARNING |
| Examples | "Never use Bash" when Bash is not in `tools`; "Always use sonnet" when `model: sonnet` | WARNING |

### 12.4 Self-Referential File Paths

| Rule | Requirement | Severity |
|------|-------------|----------|
| No redundant listings | Do not maintain a file listing section when the workflow already names each file | WARNING |
| Exception | Codebase References pointing to external files (outside the agent) are acceptable | WARNING |

### 12.5 Vague Instructions With Bounded Equivalents

| Rule | Requirement | Severity |
|------|-------------|----------|
| Prefer specificity | Replace vague quantifiers ("thorough", "comprehensive") with specific bounded equivalents when available | WARNING |
| Tolerance | Vague instructions are acceptable when no specific bounded alternative exists | WARNING |

### 12.6 Duplicate Content Across Variants

| Rule | Requirement | Severity |
|------|-------------|----------|
| No copy-paste variants | Content blocks that are 90%+ identical with only field names changed should be consolidated | WARNING |
| Approach | Use a single template with conditionals or placeholders instead of duplicated blocks | WARNING |

### 12.7 Contradictory Authority Claims

| Rule | Requirement | Severity |
|------|-------------|----------|
| Single authority | No two files within the agent may claim sole authority over the same format, process, or definition | ERROR |
| Markers | Look for "SINGLE SOURCE OF TRUTH", "this file defines", "authoritative", "canonical" | ERROR |

### 12.8 Cross-Boundary Knowledge

| Rule | Requirement | Severity |
|------|-------------|----------|
| No internal references | Do not reference another agent's internal file structure | WARNING |
| Acceptable | References to shared interface contracts are fine; internal step files of other agents are not | WARNING |

### 12.9 Orphaned References

| Rule | Requirement | Severity |
|------|-------------|----------|
| All references valid | Every file path and section reference must resolve to an existing target | ERROR |
| Scope | Check within the agent's own directory and, for external paths, within the repository | ERROR |

### 12.10 Redundant Indirection

| Rule | Requirement | Severity |
|------|-------------|----------|
| No loaded-file references | Do not cross-reference files the agent already loads in its mandatory workflow steps | WARNING |
| Scope | Applies to "(see X)", "(defined in X)", and sections that duplicate loaded content | WARNING |

### 12.11 Cross-Boundary Role References

| Rule | Requirement | Severity |
|------|-------------|----------|
| Self-contained constraints | Do not reference another agent's role or responsibility to define this agent's own behavior | WARNING |
| Operational exception | References to other agents are acceptable when there is an operational dependency (orchestrator→agent, handoff protocol) | WARNING |

### 12.12 Emphasis Calibration

| Rule | Requirement | Severity |
|------|-------------|----------|
| Proportionate emphasis | NEVER/ALWAYS/MUST/CRITICAL markers reserved for genuine safety constraints | WARNING |
| Threshold | If >3 such markers exist, each must prevent data loss, unauthorized modification, or system damage | WARNING |
| Scope | Count only ALL-CAPS occurrences, exclude code blocks and headings | WARNING |

### 12.13 Constraint Rationale

| Rule | Requirement | Severity |
|------|-------------|----------|
| Rationale required | Each constraint must include explanatory text for why it exists | WARNING |
| Bare mandates | Constraints without any rationale are flagged | WARNING |

---

## 13. Contract Validation Rules

### 13.1 Contract Existence

| Rule | Requirement | Severity |
|------|-------------|----------|
| Inter-agent contracts | Agents invoked by other agents via the Agent tool must have an interface contract | WARNING |
| Contract location (personal) | `.claude/agents/interface-contracts/<agent-name>.contract.md` | ERROR |
| Contract location (project) | `.claude/agents/interface-contracts/<agent-name>.contract.md` | ERROR |
| Standalone agents | Agents invoked only by users do not require a contract (report as N/A) | N/A |

Check both personal and project level paths for contract files.

### 13.2 Required Contract Sections

| Section | Purpose | Severity if Missing |
|---------|---------|---------------------|
| **Input** | Describes what the calling agent must provide | ERROR |
| **Output** | Describes what the agent returns | ERROR |
| **Guarantees** | Lists invariants callers can rely on | ERROR |

### 13.3 Accuracy Rules

| Rule | Requirement | Severity |
|------|-------------|----------|
| Input accuracy | Input spec must match what the agent's workflow actually accepts | ERROR |
| Output accuracy | Output spec must match what the agent actually produces | ERROR |
| No phantom parameters | Contract must not document parameters the agent does not use | ERROR |
| No internal details | Contract must not expose step files, internal state, or implementation specifics | WARNING |

### 13.4 Quality Rules

| Rule | Requirement | Severity |
|------|-------------|----------|
| Imperative language | Use imperative voice ("Provide the path") not passive ("The path should be provided") | WARNING |
| Forward slashes | All file paths use forward slashes only | WARNING |
| Example invocations | At least one realistic example prompt included | WARNING |
| Multi-mode coverage | If agent has multiple invocation modes, all must be documented | WARNING |

### 13.5 Guide Validation Rules

| Rule | Requirement | Severity |
|------|-------------|----------|
| Guide existence | All agents and skills should have a human-facing guide | WARNING |
| Guide location (personal) | `.claude/documentation/<name>.guide.md` | WARNING |
| Guide location (project) | `.claude/documentation/<name>.guide.md` | WARNING |
| Required sections | Guide must contain "What It Does" and "Related" sections | WARNING |

Check both personal and project level paths for guide files.
