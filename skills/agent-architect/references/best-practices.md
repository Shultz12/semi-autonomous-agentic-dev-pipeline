# Best Practices for Agent Design

Consolidated guidelines from Anthropic documentation and Claude Code best practices.

## Context Engineering

### Hybrid Loading Strategy

Use a combination of upfront and just-in-time context loading:

**Load Upfront (Essential)**
- Core persona and mandate
- Critical constraints and rules
- File creation locations
- Summary format requirements

**Load Just-in-Time (Context-Based)**
- Best practices references
- Pattern details
- Templates
- Examples

**Rationale**: Upfront loading ensures immediate availability of critical information. Just-in-time loading reduces token consumption and keeps context focused.

### File Loading Strategy

When an agent reads multiple files, determine the loading strategy using this matrix:

| Question | If YES → | If NO → |
|----------|----------|---------|
| Is input scope known at start? | Consider upfront | Progressive |
| Must check cross-file relationships? | Upfront required | Progressive acceptable |
| Does agent delegate to skills? | Skills load own context | Agent loads directly |
| Are files discovered during work? | Progressive | Upfront possible |

**Strategies:**

| Strategy | When to Use | Implementation |
|----------|-------------|----------------|
| **Upfront** | Fixed scope, cross-file validation | Glob directory → Read all → Process |
| **Progressive** | Dynamic scope, independent files | Load as discovered/needed |
| **Delegated** | Agent orchestrates skills | Skills manage their own file loading |

If no strategy fits cleanly, document the custom approach in the agent's workflow.

### Progressive Disclosure

Structure agent files to load content progressively:

1. **Metadata** (~100 tokens) — Name and description loaded at startup
2. **Main instructions** — Loaded when the agent is triggered. Keep tight enough that a fresh reader absorbs purpose, mode routing, and core constraints from the body alone
3. **Reference files** — Loaded only when needed; anything not required on every invocation belongs here

**Diagnostic cue**: if content would not be needed every time the agent is invoked, it belongs in a referenced file (`essentials/`, `references/`, `modes/`).

**Implementation**:
```markdown
# Main Agent File

[Core instructions — purpose, mode routing, core constraints]

## Reference Materials
- **Detailed guide**: See [references/guide.md](references/guide.md)
- **Examples**: See [references/examples.md](references/examples.md)
```

### Token Efficiency

- **Challenge every piece of information**: "Does the agent really need this?"
- **Assume intelligence**: Claude knows common concepts; don't over-explain
- **Use references**: Point to files instead of embedding large content
- **Keep main files tight**: the body holds purpose, mode routing, and core constraints — split anything not needed on every invocation into a referenced file (no fixed line cap; density varies by content type)

### Avoid Redundant Indirection

When an agent's workflow mandates loading a file (e.g., "Step 1: Read rules.md"), do not reference that file elsewhere with "(see rules.md)" or "(defined in rules.md)". The content is already in context. Cross-references to mandatory-load files add tokens without information.

| Redundant | Clean |
|-----------|-------|
| "Apply deviation rules (see `essentials/rules.md`)" | "Apply deviation rules" |
| Duplicated section from a file loaded in Step 1 | Remove section entirely |
| "(see persona file)" after persona file was loaded | Drop the parenthetical |

## Prompt Engineering

### Specificity Over Inference

Replace vague instructions with explicit guidance:

| Vague | Specific |
|-------|----------|
| "Review the code" | "Check for security vulnerabilities, focusing on input validation and SQL injection" |
| "Fix the bug" | "Identify the root cause of the null pointer exception in UserService.getById()" |
| "Write tests" | "Write unit tests covering the happy path, null inputs, and boundary conditions" |

### Right Altitude

Balance specificity and flexibility. Rigid instructions break on edge cases; vague instructions produce inconsistent behavior. Use concrete rules where correctness matters, flexible guidance where judgment is needed.

| Too Rigid | Right Altitude | Too Vague |
|-----------|---------------|-----------|
| "If file has 3+ sections, split into subdirectories named exactly..." | "Multi-file agents should organize into subdirectories (essentials/, modes/, steps/ as applicable)" | "Organize files well" |
| "Always ask exactly 4 questions per tier, in this exact order..." | "Gather information in tiered order of dependency; never ask all questions at once" | "Ask good questions" |

### Description Writing

Descriptions enable agent discovery. Write in third person with specific triggers:

**Good**:
> "Reviews code changes for security vulnerabilities, architectural compliance, and test coverage. Use when code has been modified or before merging pull requests."

**Avoid**:
> "Helps with code review" (too vague)
> "I review code for you" (wrong person)

### Instruction Language

Use imperative commands, not passive suggestions. Agents follow instructions better when they're clear mandates.

| Avoid (Passive) | Use (Imperative) |
|-----------------|------------------|
| "You should check..." | "Check..." |
| "The agent can produce..." | "Produce..." |
| "It may be helpful to..." | "Always..." |
| "Consider doing..." | "Do..." |
| "You might want to..." | "You MUST..." |

**Emphasis markers for critical instructions:**
- `MUST` / `ALWAYS` - Non-negotiable requirements
- `NEVER` - Absolute prohibitions
- `DO NOT` - Clear negatives
- **Bold text** - Important items
- ALL CAPS - Critical warnings (sparingly)

**Calibration:** Reserve `MUST`, `CRITICAL`, `ALWAYS` for genuine safety constraints and non-negotiable rules. For tool triggering and optional behaviors, use natural language: "Use this tool when..." instead of "CRITICAL: You MUST use this tool when...".

**Example - Before:**
```markdown
## Workflow
The agent should read the file first. It can then analyze the contents
and may produce a summary if helpful.
```

**Example - After:**
```markdown
## Workflow
1. Read the file
2. Analyze the contents
3. Produce a summary

**YOU MUST complete all three steps before returning output.**
```

**Why this matters:** Passive language creates ambiguity about whether an action is required or optional. Imperative commands make expectations explicit, leading to consistent agent behavior.

## Agent Design Principles

### Single Responsibility

Each agent should have ONE clear purpose:
- **Good**: "Validates code quality and security"
- **Bad**: "Reviews code, writes tests, deploys, and monitors"

Split complex responsibilities into multiple focused agents that communicate via handoffs.

### Boundary Isolation

Agent instructions must be self-contained. A **Cross-Boundary Role Reference** is when an agent's constraints reference another agent's role or responsibility to define its own behavior — even when phrased as a self-instruction. This creates implicit coupling to external agents that the agent has no operational need to know about.

| Cross-Boundary Role Reference (anti-pattern) | Correct |
|---------------------|---------|
| "Don't modify code — that's the developer's job" | "Don't modify code — diagnose and prescribe only" |
| "Leave testing to the test-runner" | "Do not execute tests" |
| "Implementation belongs to the developer" | (omit — constraint stands without this) |

**When cross-agent references ARE appropriate:**
- Orchestrators referencing agents they dispatch
- Handoff protocols naming the receiver
- Inter-Agent Communication sections

**Rule of thumb:** If you can remove the other agent's name and the constraint still makes sense, remove it.

### Constraint Enforcement Hierarchy

For every behavioral constraint, walk this hierarchy and select the highest level whose mechanism actually applies. Levels are ordered strongest (architectural, deterministic at runtime) to weakest (prompt-level, probabilistic).

| Level | Mechanism | Where it lives |
|-------|-----------|----------------|
| 1 | Tool restriction | `tools:` allowlist in YAML frontmatter |
| 2 | Permissions deny rules | `.claude/settings.json` → `permissions.deny` patterns |
| 3 | PreToolUse / PostToolUse hooks | Validation scripts that block on non-zero exit |
| 4 | Human-in-the-loop checkpoint | `AskUserQuestion`, plan mode |
| 5 | Subagent context isolation | `context: fork`, dedicated worktree |
| 6 | Positive prompt framing | Directive toward the desired action |
| 7 | Calibrated negative emphasis | `NEVER` / `MUST` / `ALWAYS` |

**Why architectural beats prompt-level**: levels 1–5 are enforced by the runtime — a misbehaving model cannot bypass them, and they cost zero runtime tokens because they are config rather than prompt content. Levels 6–7 have probabilistic compliance: measured compliance on priority-flagged constraints sits roughly in the 48–64% range even for capable models. Falling through to prompt-level only when no architectural mechanism applies minimizes both token cost and constraint-violation risk.

**Why level 6 above level 7**: positive framing ("do X") is followed more reliably than negative framing ("don't do Y"). Negative phrasing can prime the prohibited behavior — consistent with Anthropic's positive-framing guidance and the Pink Elephant / NeQA effects in the literature.

**How to apply**: for each behavioral constraint identified during design, walk levels 1–7 in order and stop at the first level whose mechanism applies. Record the chosen level, the specific mechanism, and the rationale in the Agent Summary's *Behavioral Constraints* table (see [../essentials/summary-format.md](../essentials/summary-format.md)).

### Tool Restriction

Tool restriction is level 1 of the Constraint Enforcement Hierarchy above — the strongest available enforcement mechanism. Match the allowlist to the agent's purpose:

| Agent Type | Typical Tools |
|------------|---------------|
| Read-only reviewer | Read, Grep, Glob, Bash(read commands) |
| Code modifier | Read, Edit, Write, Bash |
| Explorer | Read, Grep, Glob |
| Full autonomy | All tools |

**Principle**: Grant minimum necessary access. A reviewer shouldn't have Write access.

### Model Selection

Choose models based on task requirements:

| Task Type | Model | Rationale |
|-----------|-------|-----------|
| Simple exploration | haiku | Fast, cost-effective |
| Standard tasks | sonnet | Balanced capability |
| Complex reasoning | opus | Deep analysis |
| Match context | inherit | Consistency |

**Default to sonnet** unless specific needs dictate otherwise.

### Isolated Context (context: fork)

Use `context: fork` in skill frontmatter when:
- Skill produces verbose output that shouldn't pollute main conversation
- Skill performs extensive exploration or research
- Skill should run independently without inheriting main conversation context
- You want to preserve main conversation tokens for other work

**Example**:
```yaml
---
name: deep-research
description: Performs thorough research on a topic by exploring the codebase extensively.
context: fork
agent: Explore
model: haiku
---
```

When invoked, skill runs in an isolated subagent. Results return as a summary to the main conversation, not verbose output.

**Available agent types for forked context:**
- `Explore` - Fast codebase exploration
- `Plan` - Implementation planning
- `general-purpose` - Full capabilities

## Workflow Patterns

### Plan Before Execute

For complex tasks, require planning before implementation:

```markdown
## Workflow

1. **Analyze** - Understand the current state
2. **Plan** - Propose changes (STOP for approval)
3. **Execute** - Implement approved changes
4. **Verify** - Confirm success
```

### Feedback Loops

Include verification steps that can trigger iteration:

```markdown
1. Make changes
2. Validate changes (run linter, tests)
3. If validation fails:
   - Review error
   - Fix issue
   - Return to step 2
4. Only proceed when validation passes
```

### Checkpoints

Insert explicit approval points for irreversible or significant actions:

```markdown
Before proceeding with [action]:
1. Show proposed changes
2. Wait for user approval
3. Only execute after explicit "proceed" or "yes"
```

## Error Prevention

### Validation Before Action

Run checks before creating or modifying:

```markdown
## Pre-Creation Checklist
- [ ] YAML frontmatter valid
- [ ] Markdown structure correct
- [ ] No duplicate agent names
- [ ] Tool permissions appropriate
- [ ] Description includes triggers
```

### Explicit Error Handling

Handle errors in scripts rather than punting to the agent:

**Good**: Script catches error and provides clear message
**Bad**: Script fails and leaves agent to interpret stack trace

### Configuration Documentation

Document all configuration values with rationale:

```markdown
model: sonnet  # Balanced capability for review tasks
tools: Read, Grep, Glob  # Read-only access for safety
```

## Communication

### Consistent Terminology

Choose one term and use it throughout:

| Concept | Use | Avoid |
|---------|-----|-------|
| Agent definition | "agent" | "bot", "assistant", "helper" |
| Skill definition | "skill" | "capability", "feature", "function" |
| Handoff file | "handoff" | "output", "result", "communication" |

### Structured Output

Use consistent formats for agent outputs:

```markdown
## [Action] Report

**Status:** [Pass/Fail/Warning]

### Findings
1. [Finding with file:line reference]
2. [Finding with file:line reference]

### Recommendations
- [Actionable recommendation]

### Next Steps
- [What should happen next]
```

## Instructional Consistency

An agent's own instructions must follow the principles it teaches, recommends, or enforces.

**Why this matters:** An agent's instructions are the first demonstration of its philosophy. If an agent tells other agents to "explain the why behind every instruction" but its own constraints are bare mandates without rationale, it teaches by example the opposite of what it prescribes.

**Common violations:**
- Agent recommends calibrated emphasis but uses NEVER/ALWAYS for every rule
- Agent advises "explain the why" but its own constraints lack rationale
- Agent teaches progressive disclosure but front-loads all instructions
- Agent promotes flexibility but enforces rigid phase structure with no escape hatch

**Self-check:** Before finalizing any agent, read its constraints as if you were a new reader with no context. Do the emphasis levels feel proportionate? Does each rule explain why it matters? Would you follow the advice if you didn't know the author?

**GOOD** — Constraints follow the principles the agent teaches:
```markdown
## Core Constraints

### Safety Boundaries
- **NEVER modify files outside the target directory without approval** — changes outside
  the target scope can break other agents or introduce unintended side effects.

### Operating Principles
- Confirm ambiguous requirements before acting. Implementing based on assumptions risks
  producing agents that don't fit the codebase's architecture or the user's intent.
```
Each constraint has calibrated emphasis and explains why it exists.

**BAD** — Agent teaches calibration but doesn't practice it:
```markdown
## Core Constraints

### Never Do
1. **NEVER modify files outside the target directory**
2. **NEVER assume requirements**
3. **NEVER use passive voice**
4. **NEVER skip the summary**
```
All four rules use NEVER, but only #1 is a safety concern. #3 and #4 are stylistic preferences given safety-level emphasis. No rationale on any rule.

## Testing and Iteration

### Evaluate with Real Tasks

Test agents with actual use cases, not synthetic scenarios:

1. Run agent on representative task
2. Observe behavior and output
3. Identify gaps or issues
4. Refine instructions
5. Repeat

### Model-Specific Testing

Test with all models the agent might use:
- Haiku may need more explicit guidance
- Opus may over-explain; trim unnecessary detail
- Sonnet is typically the baseline

### Team Feedback

If agents will be shared:
- Document expected behavior
- Gather feedback from users
- Iterate based on real usage patterns
