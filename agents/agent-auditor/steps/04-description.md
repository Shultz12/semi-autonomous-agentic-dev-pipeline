# Step 4: Description Quality Validation

Validate that the description field meets quality requirements for agent discovery.

## Checks to Perform

### Check 4.1: Third Person Voice

**What to verify:**
- Description is written in third person
- Does NOT start with "I", "You", "We"
- Does NOT contain first-person references like "I will", "I can", "my"

**How to verify:**
- Read the description text
- Check for first-person pronouns

**Indicators of PASS:**
- "Reviews code...", "Creates tests...", "Validates..."
- "Explores the codebase...", "Handles..."

**Indicators of FAIL:**
- "I review code...", "I will create...", "My purpose is..."

**Pass/Fail:**
- PASS: Third person voice used
- FAIL [ERROR]: First person voice detected

### Check 4.2: WHAT Component Present

**What to verify:**
- Description explains WHAT the agent does
- Contains action verbs describing capabilities

**How to verify:**
- Look for action verbs: reviews, creates, validates, explores, handles, generates, processes, etc.
- Check that capabilities are described

**Indicators of PASS:**
- "Reviews code for security vulnerabilities"
- "Creates unit tests with mocking support"
- "Validates agent designs against standards"

**Indicators of FAIL:**
- "Code reviewer" (noun only, no action)
- "Testing helper" (vague, no specific action)

**Pass/Fail:**
- PASS: Clear action/capability described
- FAIL [ERROR]: No clear WHAT component

### Check 4.3: WHEN Component Present

**What to verify:**
- Description includes guidance on WHEN to use the agent
- Contains trigger phrases: "Use when...", "Use for...", "Call when...", "Use this agent when..."

**How to verify:**
- Search for trigger phrases
- Check for context clues about usage scenarios

**Indicators of PASS:**
- "Use when code has been modified"
- "Use for creating new test files"
- "Call when validating agent designs"

**Indicators of FAIL:**
- No mention of when/usage scenarios
- Only describes what, not when

**Pass/Fail:**
- PASS: WHEN component present
- FAIL [WARNING]: Missing WHEN guidance

### Check 4.4: Trigger Keywords Present

**What to verify:**
- Description contains keywords users would naturally use
- Keywords enable discovery when users describe their need

**How to verify:**
- Identify domain-specific keywords
- Check for action words, technology names, task types

**Indicators of PASS:**
- Contains domain terms: "security", "test", "review", "validate"
- Contains technology terms: "TypeScript", "API", "database"
- Contains action terms: "create", "check", "analyze", "fix"

**Indicators of FAIL:**
- Generic terms only: "help", "assist", "work with"
- No specific keywords for discovery

**Pass/Fail:**
- PASS: Contains searchable trigger keywords
- FAIL [WARNING]: Lacks specific trigger keywords

### Check 4.5: Specificity (Differentiation)

**What to verify:**
- Description is specific enough to differentiate from other agents
- Not too generic that it could apply to many agents

**How to verify:**
- Assess uniqueness of description
- Check if it clearly defines the agent's niche

**Indicators of PASS:**
- "Reviews agent designs against established standards" (specific domain)
- "Creates unit tests for TypeScript functions with mocking support" (specific tech + approach)

**Indicators of FAIL:**
- "Helps with coding tasks" (too broad)
- "Reviews things" (too vague)
- "General purpose helper" (no differentiation)

**Pass/Fail:**
- PASS: Specific and differentiated
- FAIL [WARNING]: Too generic, needs more specificity

---

## When Complete

Record all findings with their severity levels.

Proceed to step 05: Content Sections Validation
Read: `steps/05-content-sections.md`
