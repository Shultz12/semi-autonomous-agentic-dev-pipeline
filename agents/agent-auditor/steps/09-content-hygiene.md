# Step 9: Content Hygiene

Validate that the artifact is free of content bloat, boundary violations, and redundancy.

## Check 9.1: Cross-File Redundancy

**What to verify:**
- The same information is not stated in multiple files within the agent
- No copy-pasted paragraphs or near-identical instructions across files

**How to verify:**
- Compare content across all loaded files
- Look for repeated instructions, rules, or definitions
- Flag any paragraph or instruction block that appears in more than one file

**Examples of FAIL:**
- Main agent file and a step file both define the same output format
- Constraints listed in both the main file and a reference file verbatim
- Same "severity definitions" table repeated in multiple files

**Pass/Fail:**
- PASS: Each piece of information exists in exactly one file
- FAIL [WARNING]: Same content found in multiple files

**Applicability:** Sub-agent and skill. For single-file skills, report as ⬜ N/A.

### Check 9.2: Information Agent Can't Act On

**What to verify:**
- The agent's instructions only cover behavior the agent itself controls
- No instructions about what downstream agents, callers, or other systems should do

**How to verify:**
- Scan for instructions directed at entities other than this agent
- Look for phrases like "the calling agent should...", "the user must...", "downstream systems will..."
- Verify all instructions are actionable by this agent

**Examples of FAIL:**
- A reviewer agent containing instructions on how the architect should handle findings
- An agent file describing what the orchestrator should pass to it
- Instructions about how the user should configure their environment

**Pass/Fail:**
- PASS: All instructions are actionable by this agent
- FAIL [WARNING]: Contains instructions for entities outside this agent's control

### Check 9.3: System-Enforced Constraints

**What to verify:**
- The agent does not restate rules that frontmatter already enforces
- No prose instructions duplicating what `tools`, `disallowedTools`, `model`, or `permissionMode` already guarantee

**How to verify:**
- Compare constraint/rule sections against frontmatter fields
- Look for instructions like "never use the Bash tool" when Bash is not in the tools list
- Look for "always use sonnet" when model is already set to sonnet

**Examples of FAIL:**
- "Never use the Write tool" when Write is not in the `tools` frontmatter
- "Always operate in plan mode" when `permissionMode: plan` is set
- "You can only use Read and Grep" when `tools: Read, Grep` already restricts this

**Pass/Fail:**
- PASS: No prose duplicates what frontmatter enforces
- FAIL [WARNING]: Prose restates system-enforced constraints

### Check 9.4: Self-Referential File Paths

**What to verify:**
- The agent does not maintain a redundant list of its own files when the workflow already names each file
- No "file reference" or "directory listing" sections that duplicate what the workflow describes

**How to verify:**
- Check for sections listing the agent's own files (e.g., "Files in this agent:", "Directory structure:")
- Compare against workflow/step references that already name each file
- A Codebase References section pointing to external files is fine — this check targets self-referencing

**Examples of FAIL:**
- A "Files" section listing `steps/01-structural.md`, `steps/02-core-frontmatter.md`, etc. when the workflow already reads each step file in order
- A directory tree of the agent's own folder duplicating information available via workflow steps

**Pass/Fail:**
- PASS: No redundant self-referential file listings
- FAIL [WARNING]: Contains file listing that duplicates workflow references

**Applicability:** Sub-agent and skill. For single-file skills, report as ⬜ N/A.

### Check 9.5: Vague Instructions With Bounded Equivalents

**What to verify:**
- No unbounded or vague instructions where a specific, bounded equivalent exists
- Instructions should be precise and measurable where possible

**How to verify:**
- Scan for vague quantifiers: "thorough", "comprehensive", "carefully", "ensure quality"
- Check if a concrete equivalent could replace the vague instruction
- Only flag when a clear bounded alternative exists

**Examples of FAIL:**
- "Be thorough in your review" when "Execute all 11 steps in sequence" already defines thoroughness
- "Carefully validate all fields" when each field and its validation rule are listed in steps
- "Ensure comprehensive coverage" without defining what comprehensive means

**Examples of PASS:**
- "Be thorough in your review" in a context where no specific steps are defined (no bounded equivalent exists)
- "2-4 sentence summary" (already bounded)

**Pass/Fail:**
- PASS: Instructions are specific or no bounded equivalent exists
- FAIL [WARNING]: Vague instruction has a more specific bounded equivalent

### Check 9.6: Duplicate Content Across Variants

**What to verify:**
- No copy-pasted templates or content blocks that differ only in minor field values
- Content that varies only by a field name should use a single template with placeholders or conditional logic

**How to verify:**
- Compare similar sections across files (e.g., sub-agent vs skill variants)
- Look for blocks that are 90%+ identical with only field names changed
- Check for repeated boilerplate across step files

**Examples of FAIL:**
- Two nearly identical frontmatter validation steps, one for sub-agents and one for skills, with only field names changed and no structural differences
- Repeated boilerplate instructions copied across multiple step files word-for-word

**Pass/Fail:**
- PASS: No copy-pasted content with only minor field changes
- FAIL [WARNING]: Duplicate content blocks with trivial variations

**Applicability:** Sub-agent and skill. For single-file skills, report as ⬜ N/A.

### Check 9.7: Contradictory Authority Claims

**What to verify:**
- No two files within the agent claim sole authority over the same format, process, or definition
- Authority over a specific concern is clearly assigned to one file

**How to verify:**
- Look for phrases like "SINGLE SOURCE OF TRUTH", "this file defines", "authoritative", "canonical"
- Verify no two files claim authority over the same thing
- Cross-reference authority claims across all files

**Examples of FAIL:**
- Main agent file says "The report format is defined here" while a step file says "This step is the SINGLE SOURCE OF TRUTH for report format"
- Two step files both claiming to define the severity scale

**Pass/Fail:**
- PASS: No conflicting authority claims
- FAIL [ERROR]: Multiple files claim sole authority over the same concern

**Applicability:** Sub-agent and skill. For single-file skills, report as ⬜ N/A.

### Check 9.8: Cross-Boundary Knowledge

**What to verify:**
- The agent does not reference another agent's internal file structure
- No assumptions about how other agents organize their internal files

**How to verify:**
- Scan for file path references to other agents' directories
- Look for assumptions like "the developer agent's steps/01-setup.md" or "the plan-architect's templates/"
- References to interface contracts are acceptable — internal files are not

**Examples of FAIL:**
- "Read the developer agent's `steps/03-implementation.md`" (references internal structure)
- "The plan-architect stores templates in `templates/plan.md`" (assumes internal layout)

**Examples of PASS:**
- "Follow the developer contract at `.claude/agents/interface-contracts/developer.contract.md`" (references shared contract)
- "Pass findings to the calling agent" (no internal structure assumptions)

**Pass/Fail:**
- PASS: No references to other agents' internal file structures
- FAIL [WARNING]: References another agent's internal files

### Check 9.9: Orphaned References

**What to verify:**
- All file paths mentioned in the agent's files point to files that actually exist
- All section references (e.g., "see Section 5") point to sections that exist
- No broken links or dead references

**How to verify:**
- Collect all file path references from the agent's files
- Verify each referenced file exists (within the agent's own directory)
- Check section cross-references resolve to actual headings
- External paths (to contracts, other agents) should be verified if within the repo

**Examples of FAIL:**
- "Read: `steps/12-final.md`" but no such file exists
- "See the Output Format section" but no section with that heading exists
- Workflow references `templates/report.md` but file was deleted

**Pass/Fail:**
- PASS: All references resolve to existing files/sections
- FAIL [ERROR]: Broken reference found

### Check 9.10: Redundant Indirection

**What to verify:**
- No cross-references pointing to files the agent already loads in its mandatory workflow
- No "(see X)" or "(defined in X)" parentheticals when X is read in the agent's loading steps

**How to verify:**
- Identify the agent's mandatory file loading steps (e.g., Step 1 reads essentials and persona files)
- Scan all other sections for references to those same files
- A reference is redundant if the file is already in context by the time the reference is encountered

**Examples of FAIL:**
- Agent reads `essentials/rules.md` in Step 1, then Step 4 says "(see essentials/rules.md)"
- A section duplicates content from a file the workflow already loads, even as a cross-reference

**Examples of PASS:**
- Workflow Step 1 naming files to load (this IS the loading instruction)
- References to files NOT on the mandatory loading path

**Pass/Fail:**
- PASS: No references to files already loaded by mandatory workflow steps
- FAIL [WARNING]: Reference points to content already in context

### Check 9.11: Cross-Boundary Role References

**What to verify:**
- The agent's constraints and instructions do not reference other agents' roles or responsibilities to define its own behavior
- The agent defines itself in self-contained terms, not relative to other agents

**How to verify:**
- Scan constraints, responsibilities, and workflow for mentions of other agents by name or role
- For each mention, ask: "Does this agent need to know about the other agent to function?"
- References are acceptable ONLY when the agent has an operational dependency (e.g., orchestrator referencing agents it spawns, handoff protocol naming a receiver)
- References are NOT acceptable when used to explain why a constraint exists or to define scope by exclusion

**Examples of FAIL:**
- "Modify code — implementation belongs to the developer" (defines scope relative to developer agent's role)
- "Do not create plans — that is the plan-architect's job" (defines prohibition relative to another agent)
- "Leave testing to the test-runner" (justifies constraint via another agent's responsibility)

**Examples of PASS:**
- "Modify code — diagnose and prescribe only" (self-contained constraint)
- "Do not create plans" (standalone prohibition, no external reference)
- An orchestrator listing agents it dispatches (operational dependency)
- Inter-Agent Communication section naming handoff targets (by design)

**Pass/Fail:**
- PASS: All constraints are self-contained; external agent references are operationally justified
- FAIL [WARNING]: Constraint references another agent's role without operational need

### Check 9.12: Emphasis Calibration

**What to verify:**
- NEVER, ALWAYS, MUST, CRITICAL emphasis markers are reserved for genuine safety constraints
- Stylistic preferences and process guidelines do not use safety-level emphasis

**How to verify:**
- Count occurrences of NEVER, ALWAYS, MUST, CRITICAL (case-sensitive, ALL-CAPS only) in the agent's core definition file
- Exclude occurrences inside code blocks (```...```) and markdown headings (lines starting with #)
- If more than 3 such markers exist, examine each:
  - Does the rule prevent data loss, unauthorized modification, or system damage? → Safety constraint, emphasis justified
  - Is the rule a stylistic preference, process guideline, or design principle? → Emphasis disproportionate
- Flag rules where emphasis level does not match actual severity

**Examples of FAIL:**
- "NEVER use passive voice in output" (stylistic preference with safety-level emphasis)
- "ALWAYS start responses with a greeting" (process guideline with safety-level emphasis)
- 8 NEVER rules where only 2 are genuine safety constraints

**Pass/Fail:**
- PASS: ≤3 emphasis markers OR all markers correspond to genuine safety constraints
- FAIL [WARNING]: Emphasis markers used for non-safety concerns

### Check 9.13: Constraint Rationale

**What to verify:**
- Each constraint in the "Core Constraints" section (or equivalent) includes a rationale explaining why it exists

**How to verify:**
- Locate the constraints section in the agent's core definition file
- For each constraint, check whether explanatory text follows the rule (inline rationale, a dash followed by explanation, or a "why" annotation)
- Flag constraints that are bare mandates with no explanation of consequence or reasoning

**Examples of FAIL:**
- "NEVER modify files outside the target directory" (no rationale — compare: "NEVER modify files outside the target directory — changes outside the target scope can break other agents")
- A list of 5 "Always Do" rules where none explain why they matter

**Examples of PASS:**
- "NEVER delete summary items without approval — design decisions in the summary may not be recoverable if removed"
- "Confirm ambiguous requirements before acting. Implementing based on assumptions risks producing agents that don't fit the codebase's architecture."

**Pass/Fail:**
- PASS: All constraints include rationale OR no constraints section exists
- FAIL [WARNING]: Constraints found without accompanying rationale

### Check 9.14: Rationale Discipline

**What to verify:**
- Judgment rationale (reasoning the LLM needs to apply a rule correctly on edge cases) is kept, compressed to one line in `Rule. **Why:** reason.` format
- Maintainer rationale (incident history, past design choices, author thought process, restated rules, section-purpose preambles) is absent

**How to verify:**
- Scan for rationale paragraphs longer than one line following a rule — apply the test: "If this were removed, would the LLM still apply the rule correctly on edge cases?" If yes → flag for compression or deletion.
- Scan for `(Rationale: …)`, `Note: …`, or parenthetical explanation blocks — flag any that do not change rule application.
- Scan for sections explaining *why the skill/agent was created*, *past design decisions*, or *incident references* ("we added this after the X incident") — flag for deletion.
- Scan for paragraphs that restate a rule already stated nearby — flag as redundant.
- Scan for section-purpose preambles ("This section covers…", "This skill is designed to…") — flag for deletion; section heading and `description:` field convey purpose.

**Examples of FAIL:**
- A 15-line `(Rationale: …)` block following a two-line rule that the LLM applies mechanically
- "We added this after the parsing incident in Q3" appearing anywhere in a runtime file
- A paragraph after a rule that simply restates the rule in longer form
- "This section exists to document…" preamble at the top of a section

**Examples of PASS:**
- `Read only the current phase — future phases may be updated and reading ahead risks stale data.` (one-line judgment rationale, load-bearing)
- A mechanical rule with no rationale attached (rule is self-explanatory)

**Pass/Fail:**
- PASS: Kept rationale is one line and load-bearing; no maintainer rationale present
- FAIL [WARNING]: Rationale paragraph exceeds one line, or maintainer rationale (history, restated rule, section preamble) is present

---

## When Complete

Record all findings with their severity levels.

Proceed to step 10: Contract Validation
Read: `steps/10-contract-validation.md`
