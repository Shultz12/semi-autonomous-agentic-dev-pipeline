# Step 7: Patterns Validation

Validate that appropriate patterns are selected and properly implemented in the agent's content.

## Pattern Requirements by Type

Refer to `agent-standards.md` section 9.1 for the pattern-to-agent-type mapping table.

## Checks to Perform

### Check 7.1: Appropriate Patterns for Agent Type

**What to verify:**
- Agent type has been correctly identified
- Required patterns for that type are mentioned or implemented

**How to verify:**
- Identify agent type from purpose/description
- Check if required patterns are present in workflow or constraints

**Pass/Fail:**
- PASS: Required patterns for type are present
- FAIL [WARNING]: Missing recommended pattern for agent type

### Check 7.2: Loop Guards Implementation

**What to verify:**
- If agent has iteration or retry logic
- Loop guards should be implemented

**Implementation markers:**
- Maximum attempt number specified (e.g., "max 3 attempts")
- Escalation procedure defined
- Termination conditions stated

**How to verify:**
- Search for iteration/retry logic
- Check for max attempts and escalation

**Pass/Fail:**
- PASS: No iteration OR guards implemented
- FAIL [WARNING]: Iteration without loop guards

### Check 7.3: Tool Execution Verification Implementation

**What to verify:**
- If agent is reviewer/validator type
- Claims must be backed by tool output

**Implementation markers:**
- "Verification Protocol" section exists
- Workflow mentions verifying with tool output
- Contains "verify", "validate with", "confirm via"
- Trust protocol defined

**How to verify:**
- Check for verification protocol section
- Search workflow for verification language

**Pass/Fail:**
- PASS: Not reviewer OR verification implemented
- FAIL [ERROR]: Reviewer without Tool Execution Verification

### Check 7.4: File Loading Strategy

**When required:**
- Agent reads multiple files (uses Glob, reads directories)
- Workflow involves processing file sets

**What to verify:**
- Loading strategy documented if multi-file
- Strategy matches agent's scope and purpose

**Decision criteria:**
| Condition | Expected Strategy |
|-----------|-------------------|
| Fixed scope + cross-file checks | Upfront loading |
| Dynamic scope or independent files | Progressive loading |
| Delegates to skills | Delegated loading |

**Pass/Fail:**
- PASS: Single-file agent OR loading strategy documented
- FAIL [WARNING]: Multi-file agent without loading strategy

---

## Pattern Implementation Detail Checks

For each pattern identified as needed, verify implementation depth:

### Search Before Code Pattern

**Markers:**
- Workflow includes search/find step before implementation
- References checking existing code first
- Contains "search", "find existing", "check for"

### Handoff Protocol Pattern

**Markers:**
- Inter-Agent Communication section exists
- Handoff format specified
- Input/output contract defined

### Defense-in-Depth Pattern

**Markers:**
- Multiple validation layers mentioned
- Cross-validation between sources
- Redundant checks specified

### Pre-Computational Logic Pattern

**Markers:**
- Validation before generating output
- Assumption checking step
- Requirements verification before work

### Check 7.5: Pattern File Completeness

**When required:**
- Agent has pattern files in `patterns/` directories

**What to verify:**
- Each pattern file contains the five required sections: Purpose, When to Apply, Implementation, Rationale, Example

**How to verify:**
- Glob for pattern files in the agent's pattern directories
- Read each pattern file
- Check for the presence of each required section (by heading)
- Flag missing Rationale or Example sections specifically

**Pass/Fail:**
- PASS: No pattern files OR all pattern files have all five sections
- FAIL [INFO]: Pattern file missing Rationale or Example section

### Check 7.6: Constraint Enforcement Hierarchy Compliance

**What to verify:**
- Prose-level constraints (level 6 positive framing or level 7 ALL-CAPS NEVER/MUST/ALWAYS) are not used where a higher-tier mechanism (levels 1–5) was available
- The seven levels, from strongest to weakest: (1) tool restriction in `tools:` allowlist, (2) `permissions.deny` patterns, (3) PreToolUse / PostToolUse hooks, (4) `AskUserQuestion` / plan mode, (5) `context: fork` / dedicated worktree, (6) positive prompt framing, (7) calibrated negative emphasis

**How to verify:**
- Locate prose constraints in the agent's main file (Core Constraints, Safety Boundaries, Operating Principles, or equivalent)
- For each constraint, scan for marker phrases that indicate an architectural alternative was available:

| Constraint phrase pattern | Higher-tier mechanism that was available | What to check is missing |
|---------------------------|------------------------------------------|--------------------------|
| "never use [tool]" / "must not invoke [tool]" | Level 1: `tools:` allowlist | Tool absent from `tools:` (overlaps Check 9.3 — defer there if 9.3 already flagged) |
| "never write to [path]" / "must not modify [pattern]" | Level 2: `permissions.deny` | No matching deny pattern in `.claude/settings.json` for the path |
| "validate [input] before executing [tool]" / "block when [condition]" | Level 3: PreToolUse hook | No `hooks.PreToolUse` entry for the relevant tool |
| "ask the user before [action]" / "confirm before [action]" / "require approval before [X]" | Level 4: `AskUserQuestion` invocation | Workflow contains no `AskUserQuestion` call at the relevant step |
| "run in isolation" / "do not pollute the main context" / "produce verbose output without affecting the caller" | Level 5: `context: fork` (skills) | Skill frontmatter missing `context: fork` |
| Negative ALL-CAPS framing on a non-safety rule | Level 6: positive framing | Rule could be reworded as a directive ("Do X") instead of a prohibition |

- A constraint that *could* have been enforced by levels 1–5 but is enforced only at level 6 or 7 is a hierarchy violation.
- A constraint that only level 6 or 7 can express (judgment call, posture, stylistic guidance) is acceptable at prose level.

**Examples of FAIL:**
- "NEVER modify files outside the target directory" — agent has Write in tools and no `permissions.deny` restricts the path. Level 2 (or a PreToolUse hook at level 3) was available.
- "Always ask the user before deleting any artifact" — workflow never invokes `AskUserQuestion` for delete operations. Level 4 was available.
- "Run extensive exploration without polluting the main conversation" — skill has no `context: fork`. Level 5 was available.

**Examples of PASS:**
- "Confirm ambiguous requirements before acting" — judgment call about when to ask; level 6 is the only suitable mechanism.
- "Write agent files as standalone documents, not changelogs" — stylistic posture; no architectural alternative.
- A prose rule paired with the matching frontmatter / hook / deny pattern that also enforces it (defense-in-depth — prose is reinforcement, not sole mechanism).

**Confidence calibration:**
- HIGH when the architectural alternative is unambiguously absent and the prose phrase clearly maps to a specific level (e.g., named tool not in allowlist).
- MEDIUM when the prose-to-mechanism mapping requires interpretation.

**Pass/Fail:**
- PASS: All prose constraints sit at the highest applicable hierarchy level, OR they genuinely belong at level 6/7.
- FAIL [WARNING]: Prose constraint encodes a behavior that levels 1–5 could enforce architecturally, but the architectural mechanism is absent.

---

## When Complete

Record all findings with their severity levels.

Proceed to step 08: Coherence Validation
Read: `steps/08-coherence.md`
