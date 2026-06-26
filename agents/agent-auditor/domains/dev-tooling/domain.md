# Domain: dev-tooling

## Scope

Agents and skills that operate within Claude Code projects — creating, validating, or managing artifacts in the `.claude/` directory structure. Includes agent architects, auditors, plan architects, developers, and other tooling that powers the Claude Code agent ecosystem.

---

## Domain Checks

Checks are numbered by the base step they extend: `<step>.D<n>`.

### Step 1 Extensions: Structural

#### Check 1.D1: Internal File Organization

**What to verify:**
- Step files (if any) are in a `steps/` subdirectory
- Reference files (if any) are in organized subdirectories (e.g., `reference/`, `templates/`, `modes/`)
- No loose files dumped in the agent's root alongside the main definition

**Note:** Base check 1.2 already validates the top-level location (`.claude/agents/<name>/`). This check validates internal organization conventions specific to dev-tooling agents.

**Pass/Fail:**
- PASS: Internal file structure follows dev-tooling conventions
- FAIL [WARNING]: Non-standard internal file organization

#### Check 1.D2: Pipeline I/O Conventions

**What to verify:**
- If the agent participates in a pipeline (reads from or writes to shared directories)
- Pipeline artifacts use `.project/cycles/<cycle>/execution/` paths (not `.claude/handoff/`)
- Auditor reviews use `.claude/reviews/<auditor-name>/`
- Agent documents what it reads from and writes to

**Pass/Fail:**
- PASS: Not a pipeline participant, OR I/O conventions documented correctly
- FAIL [WARNING]: Pipeline participant without documented I/O conventions

### Step 7 Extensions: Behavioral Patterns

#### Check 7.D1: Feedback Loop Implementation

**What to verify:**
- If agent has iterative or pipeline workflows that refine output through repeated passes
- Feedback loop should implement the Execute-Validate-Assess-Decide cycle
- Must be combined with Loop Guards (bounded iteration)

**Implementation markers:**
- Iteration protocol with distinct phases (execute, validate, assess, decide)
- Quality checks specified (e.g., lint, types, tests)
- Explicit "if passed: proceed / if failed: retry" branching
- Reference to or implementation of Loop Guards for bounding

**Pass/Fail:**
- PASS: Not an iterative agent, OR feedback loop with quality gates and bounded iteration
- FAIL [WARNING]: Iterative agent without structured feedback loop
- FAIL [WARNING]: Feedback loop present but missing quality gate definitions

#### Check 7.D2: Progressive Question Flow

**What to verify:**
- If agent is interactive and gathers requirements through questions
- Questions should be organized in tiers (not all asked at once)
- Each tier should have 1-2 questions maximum
- Agent must wait for answers before proceeding to the next tier

**Implementation markers:**
- Tier structure (e.g., Tier 1 Core, Tier 2 Behavior, Tier 3 Technical, Tier 4 Refinement)
- "1-2 questions" or equivalent per-tier limit
- "Wait for answers" or equivalent gate between tiers
- Progressive dependency (later tiers informed by earlier answers)

**Pass/Fail:**
- PASS: Not an interactive agent, OR progressive question tiers implemented
- FAIL [WARNING]: Interactive agent that asks all questions at once without tiering

### Step 7 Extensions (continued): Output Enforcement

#### Check 7.D3: Output Enforcement Pattern

**What to verify:**
- If the agent has Write in its tools list AND writes mandatory output files (not just conditional writes)
- Agent has a `## Completion Gate` section
- Agent's workflow includes an output path registration step that runs `echo "[path]" > /tmp/.claude-agent-output-target` via Bash
- Registration happens early in the workflow (before the heavy analysis/implementation work), not at the end
- If the agent writes mandatory files but lacks Bash in its tools, flag as missing (Bash is required for registration)

**Implementation markers:**
- `## Completion Gate` section present
- Bash command containing `/tmp/.claude-agent-output-target` in workflow
- Registration step positioned before analysis/implementation steps

**Pass/Fail:**
- PASS: Agent does not write mandatory output files, OR all three markers present (Completion Gate, registration command, early positioning)
- FAIL [WARNING]: Agent writes mandatory files but missing Completion Gate section
- FAIL [WARNING]: Agent has Completion Gate but missing registration step in workflow
- FAIL [WARNING]: Registration step exists but positioned after heavy work (should be early)
- FAIL [ERROR]: Agent writes mandatory files, has Write tool, but no output enforcement at all

#### Check 7.D4: Self-Criticism & Disconfirmation

**What to verify:**
- If the agent produces verdicts, classifications, or findings that downstream agents act on
- Agent has a self-criticism protocol that runs AFTER analysis but BEFORE writing findings
- Protocol includes at minimum: disconfirmation check (seeking evidence against conclusion) and severity check (verifying classification isn't inflated)

**Implementation markers:**
- Explicit "self-criticism", "disconfirmation", or "challenge your conclusion" section
- Runs after analysis, before output — not a pre-analysis validation (that's Pre-Computational Logic)
- At least 2 of: disconfirmation check, severity check, attribution check, completeness check

**Pass/Fail:**
- PASS: Agent does not produce classified findings, OR self-criticism protocol present with at least 2 checks
- FAIL [WARNING]: Agent produces classified findings but has no self-criticism step
- FAIL [INFO]: Self-criticism present but only 1 check type (recommend adding more)

#### Check 7.D5: Severity + Confidence Pairing

**What to verify:**
- If the agent classifies findings by severity/priority
- Findings include both a severity level AND a confidence level as independent dimensions
- A closed set of severity levels is defined (not open-ended labels)
- LOW confidence findings are handled (investigated further or reframed, never shipped to downstream)

**Implementation markers:**
- Severity table with closed set of levels
- Confidence table with at least HIGH/MEDIUM levels
- Rule that LOW confidence findings are not reported (deepened or reframed)
- Output format shows both severity and confidence per finding

**Pass/Fail:**
- PASS: Agent doesn't classify findings, OR both dimensions defined with closed sets
- FAIL [WARNING]: Agent classifies findings by severity only, no confidence dimension
- FAIL [WARNING]: Confidence levels defined but no rule preventing LOW-confidence findings from shipping

#### Check 7.D6: Escalation Routing

**What to verify:**
- If the agent participates in an orchestrated pipeline and could encounter unresolvable situations
- Agent has a "never ask user directly" constraint
- Agent defines structured escalation categories and format
- Agent commits partial work before escalating (if applicable)

**Implementation markers:**
- "Never ask the user directly" or equivalent in constraints
- Structured escalation format (Status, Blocked By, Problem Report, or equivalent)
- Escalation categories mapping to downstream handlers
- Partial commit before BLOCKED/CHECKPOINT (for code-modifying agents)

**Pass/Fail:**
- PASS: Agent is user-facing or autonomous (no pipeline), OR escalation routing fully defined
- FAIL [WARNING]: Pipeline agent that can ask user directly (no escalation constraint)
- FAIL [WARNING]: Escalation constraint exists but no structured format defined
- FAIL [INFO]: Escalation format exists but no partial commit protocol (acceptable for read-only agents)

#### Check 7.D7: Savepoint & Deterministic Revert

**What to verify:**
- If the agent modifies files/state that might need rollback after a failed verification step
- Agent creates a checkpoint before verification
- Agent has a deterministic revert mechanism (not just "undo the changes")
- Revert covers both tracked and untracked files (if using git)

**Implementation markers:**
- Savepoint creation step (git commit, file archive, or equivalent) before verification
- Explicit revert commands (both `git checkout -- .` AND `git clean -fd`, or archive restore)
- Fix attempts operate on savepoint state, not cumulative state
- Original errors preserved through fix attempts (not overwritten)

**Note:** The commit *form* and `Agent:` attribution trailer for git savepoints come from the `commit-to-git` skill and are validated under Pipeline Conformance (committer role); this check is scoped to the savepoint/revert *mechanism* only.

**Pass/Fail:**
- PASS: Agent is read-only or changes are always additive, OR savepoint protocol fully defined
- FAIL [WARNING]: Agent modifies files and has verification but no savepoint/revert mechanism
- FAIL [WARNING]: Savepoint exists but revert only handles tracked files (missing `git clean -fd` or equivalent)

---

## Additional Checklist Count

**9 additional checks** (1.D1, 1.D2, 7.D1, 7.D2, 7.D3, 7.D4, 7.D5, 7.D6, 7.D7)

---

## Alignment

Domain name `dev-tooling` aligns with Agent Architect's dev-tooling domain.
