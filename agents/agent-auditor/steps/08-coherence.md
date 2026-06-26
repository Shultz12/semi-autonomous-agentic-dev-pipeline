# Step 8: Coherence and Duplication Validation

Validate semantic coherence across all components and check for duplication with existing agents.

## Coherence Checks

### Check 8.1: Purpose-Tools Alignment

**What to verify:**
- Tools granted are coherent with stated purpose
- No contradictions between what agent claims to do and tools available

**How to verify:**
- Re-read purpose from description and mandate
- Compare against tool list
- Flag any inconsistencies

**Examples of FAIL:**
- Purpose: "Read-only security reviewer" but has Edit, Write tools
- Purpose: "Creates test files" but only has Read, Grep, Glob
- Purpose: "Explores codebase" but has bypassPermissions mode

**Pass/Fail:**
- PASS: Purpose and tools are coherent
- FAIL [ERROR]: Contradiction between purpose and tools

### Check 8.2: Purpose-Model Alignment

**What to verify:**
- Model selection is coherent with task complexity
- Non-default model choice is justified by purpose

**How to verify:**
- Identify model selection
- Compare against purpose complexity

**Alignment expectations:**
| Purpose Complexity | Expected Model |
|--------------------|----------------|
| Simple, repetitive tasks | haiku |
| Standard tasks | sonnet (default) |
| Complex reasoning, architecture | opus |
| Context-dependent | inherit |

**Examples of FAIL:**
- Purpose: "Simple file search" but model: opus (overkill)
- Purpose: "Complex architectural decisions" but model: haiku (underpowered)

**Pass/Fail:**
- PASS: Model appropriate for purpose complexity
- FAIL [WARNING]: Model may not match task complexity

### Check 8.3: Purpose-Patterns Alignment

**What to verify:**
- Selected patterns are coherent with stated purpose
- Required patterns for purpose are present

**How to verify:**
- Identify patterns in use (from workflow, constraints)
- Compare against purpose requirements

**Examples of FAIL:**
- Purpose: "Reviewer" without Tool Execution Verification
- Purpose: "Orchestrator" without Handoff Protocol

**Pass/Fail:**
- PASS: Patterns coherent with purpose
- FAIL [WARNING]: Pattern selection doesn't match purpose

### Check 8.4: Internal Consistency

**What to verify:**
- No contradictions within the agent definition itself
- Constraints don't conflict with responsibilities
- Workflow matches stated responsibilities

**How to verify:**
- Cross-reference constraints with responsibilities
- Verify workflow covers all responsibilities

**Examples of FAIL:**
- Constraint: "Never modify files" but Responsibility: "Fix identified issues"
- Responsibility: "Generate reports" but no Output Format section

**Pass/Fail:**
- PASS: Internally consistent
- FAIL [ERROR]: Internal contradictions found

---

## Duplication Check

### Check 8.5: Scan Existing Agents

**What to verify:**
- No existing agent has significantly overlapping responsibilities

**How to verify:**
1. Use Glob to find: `.claude/agents/**/*.md`
2. Read description and responsibilities from each
3. Compare against new agent's purpose

**Pass/Fail:**
- PASS: No significant overlap
- FAIL [WARNING]: Potential overlap with [agent-name]

### Check 8.6: Scan Existing Skills

**What to verify:**
- No existing skill has significantly overlapping functionality

**How to verify:**
1. Use Glob to find: `.claude/skills/**/SKILL.md`
2. Read description from each
3. Compare against new agent's purpose

**Pass/Fail:**
- PASS: No significant overlap
- FAIL [WARNING]: Potential overlap with [skill-name]

### Check 8.7: Reference-Instruction Consistency

**What to verify:**
- The agent's own instructions follow the principles stated in its reference files

**How to verify:**
- If the agent has reference files (in `references/`, `essentials/`, or similar), scan them for stated principles
- Apply these heuristic checks against the agent's core definition file:

| Reference Principle | Heuristic Check |
|---------------------|-----------------|
| "calibrate emphasis" or "reserve MUST/NEVER for safety" | Count NEVER/ALWAYS/MUST in constraints (excluding code blocks and headings). If >3, check whether each is a genuine safety constraint |
| "explain the why" or "include rationale" | Check whether constraints in the core definition have accompanying rationale |
| "progressive disclosure" | Check whether all instructions are front-loaded in the main file vs distributed across reference files |
| "balance specificity and flexibility" or "right altitude" | Check whether rules are overly rigid (exact counts, exact sequences) for non-critical concerns |

- Only flag when a reference file explicitly states a principle AND the agent's own instructions visibly violate it
- Do not flag for principles that are ambiguous or not clearly stated in the reference material

**Examples of FAIL:**
- Reference says "calibrate emphasis — reserve NEVER for genuine safety constraints" but agent has 7 NEVER rules including "NEVER use passive voice"
- Reference says "explain the why behind every instruction" but agent has 5 bare constraints with no rationale

**Pass/Fail:**
- PASS: No reference files OR agent's instructions are consistent with its own reference principles
- FAIL [WARNING]: Agent's instructions contradict principles stated in its own reference material

### Check 8.8: Output Persistence (Self-Commit)

**What to verify:**
- An artifact that writes files into the project repository commits them itself via a final workflow step

**How to verify:**
- Scan the workflow for Write/Edit targets:
  - **Project-level paths** (`.project/`, project source, project-level `.claude/`, any repo-relative path) → the artifact must have a final-step instruction to commit those files by referencing the `commit-to-git` skill through progressive disclosure (sub-agent: Read `.claude/skills/commit-to-git/SKILL.md` at the commit step; skill: invoke via the Skill tool). The reference must NOT be preloaded via `skills:` frontmatter.
  - **Only user-level paths** (`.claude/...`) or no file writes → no commit step expected; report N/A.
- If the artifact is a pipeline participant that embodies Role A (committer) — validated under Pipeline Conformance PC.A1 in Phase 4.2 — record this check as N/A (deferred to PC.A1) to avoid double-counting.

**Examples of FAIL:**
- An agent that writes plans under `.project/cycles/.../plans/` with no commit step anywhere in its workflow
- A skill that generates project source files but never commits them, leaving a dirty tree for the caller
- An agent that lists `commit-to-git` under `skills:` frontmatter instead of Reading it at its commit step (defeats progressive disclosure)

**Examples of PASS:**
- An agent whose final step Reads `.claude/skills/commit-to-git/SKILL.md` and commits the paths it wrote, passing `Agent: <name>`
- A reviewer that writes only to `.claude/reviews/` (N/A — user-level)

**Pass/Fail:**
- PASS: Project-writing artifact commits its output via a progressive-disclosure reference to commit-to-git; OR writes only user-level files (N/A); OR deferred to PC.A1
- FAIL [WARNING]: Project-writing artifact has no self-commit step, or references commit-to-git via frontmatter preload

---

## Overlap Assessment Criteria

When comparing agents/skills, consider:

**Significant Overlap:**
- Same primary purpose
- Same target domain
- Similar trigger keywords
- Would be chosen for same user requests

**Acceptable Differentiation:**
- Different scope (one is subset of other)
- Different approach (same goal, different method)
- Different specialization (same domain, different focus)

---

## When Complete

Record all findings with their severity levels.

Proceed to step 09: Content Hygiene
Read: `steps/09-content-hygiene.md`
