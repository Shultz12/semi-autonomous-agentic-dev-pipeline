# Step 2: Agent Architect domain.md Quality

Validate the Agent Architect's domain definition file at `.claude/skills/agent-architect/domains/<name>/domain.md`.

## Checks to Perform

### Check 2.1: Scope Section Present

**What to verify:**
- A `## Scope` section exists
- Contains a bullet list with specific criteria for when the domain applies
- Criteria are concrete (not vague like "relevant agents")

**How to verify:**
- Search for `## Scope` heading in the file
- Verify bullet list follows with at least 2 items

**Pass/Fail:**
- PASS: Scope section present with specific bullet criteria
- FAIL [ERROR]: Scope section missing or contains only vague criteria

### Check 2.2: Required Scans Table Present

**What to verify:**
- A `### Required Scans` subsection exists under `## Project Scanning`
- Contains a table with columns: Scan, Command, Purpose

**How to verify:**
- Search for `### Required Scans` heading
- Verify a markdown table follows with the expected columns

**Pass/Fail:**
- PASS: Required Scans table present with correct columns
- FAIL [ERROR]: Required Scans table missing or malformed

### Check 2.3: Optional Scans Table Present

**What to verify:**
- A `### Optional Scans` subsection exists, OR
- Its absence is explicitly justified (e.g., "No optional scans needed for this domain")

**How to verify:**
- Search for `### Optional Scans` heading
- If absent, check for explicit justification text

**Pass/Fail:**
- PASS: Optional Scans table present, or absence justified
- FAIL [WARNING]: Optional Scans section missing without justification

### Check 2.4: Conventions Section Present

**What to verify:**
- A `## Conventions` section exists
- Contains convention entries (bold name + explanation pattern)

**How to verify:**
- Search for `## Conventions` heading
- Verify at least one convention follows

**Pass/Fail:**
- PASS: Conventions section present with entries
- FAIL [ERROR]: Conventions section missing

### Check 2.5: Convention Quality

**What to verify:**
- Each convention is specific, actionable, and verifiable
- Not vague or subjective ("well-designed", "clean code", "best practices")
- Could be checked by grep/glob/read commands

**How to verify:**
- Read each convention entry
- Apply the quality test: "Can an auditor write a pass/fail rule for this?"
- Flag any convention that fails this test

**Pass/Fail:**
- PASS: All conventions are specific, actionable, and verifiable
- FAIL [WARNING]: Convention is vague — `[quote the vague convention]`

### Check 2.6: Tool Recommendations Table Present

**What to verify:**
- A `## Tool Recommendations` section exists
- Contains a table mapping agent types to recommended tools with rationale

**How to verify:**
- Search for `## Tool Recommendations` heading
- Verify a markdown table follows

**Pass/Fail:**
- PASS: Tool Recommendations table present
- FAIL [WARNING]: Tool Recommendations section missing

### Check 2.7: Domain Resources Section Present

**What to verify:**
- A `## Domain Resources` section exists
- Links to patterns (`patterns/_index.md`) and templates (if applicable)

**How to verify:**
- Search for `## Domain Resources` heading
- Verify links to pattern index and any templates

**Pass/Fail:**
- PASS: Domain Resources section present with links
- FAIL [WARNING]: Domain Resources section missing

---

## When Complete

Record all findings with their severity levels.

Proceed to step 03: Pattern & Template Validation
Read: `steps/03-patterns.md`
