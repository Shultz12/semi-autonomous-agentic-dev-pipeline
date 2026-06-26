# Step 3: Type-Specific Frontmatter Validation

Validate frontmatter fields specific to sub-agents OR skills based on artifact type detected in Step 1.

---

## Sub-Agent Specific Checks

If reviewing a sub-agent, perform these checks:

### Check 3A.1: Tools Field Format

**What to verify:**
- If `tools` field exists, it's a comma-separated list
- Tool names are valid (Agent, AskUserQuestion, Bash, Edit, Glob, Grep, LSP, NotebookEdit, Read, Skill, WebFetch, WebSearch, Write, TaskCreate, TaskGet, TaskList, TaskUpdate, TodoWrite, plus MCP tool names)

**How to verify:**
- Parse tools value
- Split by comma and validate each tool name

**Pass/Fail:**
- PASS: Tools absent (full access) or valid list
- FAIL [ERROR]: Invalid tool name in list

### Check 3A.2: Disallowed Tools Field Format

**What to verify:**
- If `disallowedTools` field exists, it's a comma-separated list
- Tool names are valid

**How to verify:**
- Parse disallowedTools value
- Validate each tool name

**Pass/Fail:**
- PASS: Field absent or valid list
- FAIL [ERROR]: Invalid tool name in disallowed list

### Check 3A.3: Tools and Disallowed Tools Conflict

**What to verify:**
- No overlap between `tools` and `disallowedTools`

**How to verify:**
- Compare both lists if both exist

**Pass/Fail:**
- PASS: No conflict
- FAIL [ERROR]: Same tool in both lists

### Check 3A.4: Name/Description Character Limits

**What to verify:**
- Name under reasonable length (recommended: under 50 chars)
- Description under reasonable length (recommended: under 300 chars)

**How to verify:**
- Measure string lengths

**Pass/Fail:**
- PASS: Within limits
- FAIL [WARNING]: Exceeds recommended limits

---

## Skill Specific Checks

If reviewing a skill, perform these checks:

### Check 3B.1: Allowed Tools Field

**What to verify:**
- If `allowed-tools` field exists, it's a comma-separated list
- Tool names are valid

**How to verify:**
- Parse allowed-tools value
- Validate each tool name

**Pass/Fail:**
- PASS: Field absent or valid list
- FAIL [ERROR]: Invalid tool name

### Check 3B.2: Context Field (if present)

**What to verify:**
- If `context` field exists, it has valid value
- Valid value: `fork`

**How to verify:**
- Parse context value

**Pass/Fail:**
- PASS: Absent or valid
- FAIL [ERROR]: Invalid context value

### Check 3B.3: Agent Field (required if context:fork)

**What to verify:**
- If `context: fork`, then `agent` field must exist
- Valid values: `Explore`, `Plan`, `general-purpose`

**How to verify:**
- Check for context field
- If fork, validate agent field exists and is valid

**Pass/Fail:**
- PASS: Not fork context, or agent field valid
- FAIL [CRITICAL]: Fork context without valid agent field

### Check 3B.4: User Invocable Field

**What to verify:**
- If `user-invocable` exists, it's a boolean (true/false)

**How to verify:**
- Parse user-invocable value

**Pass/Fail:**
- PASS: Absent or valid boolean
- FAIL [ERROR]: Invalid boolean value

### Check 3B.5: Disable Model Invocation Field

**What to verify:**
- If `disable-model-invocation` exists, it's a boolean (true/false)

**How to verify:**
- Parse field value

**Pass/Fail:**
- PASS: Absent or valid boolean
- FAIL [ERROR]: Invalid boolean value

### Check 3B.6: Argument Hint Field

**What to verify:**
- If `argument-hint` exists, it's a non-empty string

**How to verify:**
- Parse field value

**Pass/Fail:**
- PASS: Absent or valid string
- FAIL [WARNING]: Empty argument hint

### Check 3B.7: Hooks Field (if present)

**What to verify:**
- If `hooks` field exists, it has valid structure
- Should be an object with valid hook types

**How to verify:**
- Parse hooks value
- Validate structure

**Pass/Fail:**
- PASS: Absent or valid structure
- FAIL [ERROR]: Invalid hooks structure

### Check 3B.8: Skill Name Length

**What to verify:**
- Skill name is under 64 characters

**How to verify:**
- Measure name length

**Pass/Fail:**
- PASS: Under 64 characters
- FAIL [ERROR]: Exceeds 64 character limit

---

## Domain Field Check (Both Types)

### Check 3.D1: Domain Field Present

**What to verify:**
- `domain` field exists in frontmatter
- Value matches a known domain (`dev-tooling`, `web-automation`)

**How to verify:**
- Parse frontmatter for `domain` field
- Compare value against known domains from `domains/_index.md`

**Pass/Fail:**
- PASS: `domain` present and matches a known domain
- FAIL [WARNING]: `domain` field missing (no domain-specific checks will be applied)
- FAIL [WARNING]: `domain` value not recognized (skip domain-specific checks)

**Side effect:** If domain is found and valid, record it for use in step 7 (domain-aware pattern validation).

---

## When Complete

Record all findings with their severity levels.
Note which check set you used (3A for sub-agent, 3B for skill).
Note whether a domain was detected and if it is known.

Proceed to step 04: Description Quality Validation
Read: `steps/04-description.md`
