# Step 1: Structural Validation

Validate the physical structure of the domain knowledge pack.

## Checks to Perform

### Check 1.1: Domain Name Format (kebab-case)

**What to verify:**
- Domain name uses lowercase letters, numbers, and hyphens only
- No underscores, spaces, or uppercase letters
- Pattern: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`

**How to verify:**
- Extract the domain name from the review request
- Validate against kebab-case pattern

**Pass/Fail:**
- PASS: Name matches kebab-case pattern
- FAIL [CRITICAL]: Name contains invalid characters

### Check 1.2: Agent Architect Directory Exists

**What to verify:**
- Directory exists at `.claude/skills/agent-architect/domains/<name>/`
- Contains at minimum a `domain.md` file

**How to verify:**
- Glob for `.claude/skills/agent-architect/domains/<name>/**/*`
- Verify `domain.md` is among the results

**Pass/Fail:**
- PASS: Directory exists with `domain.md`
- FAIL [CRITICAL]: Directory or `domain.md` missing

### Check 1.3: Agent Auditor Directory Exists

**What to verify:**
- Directory exists at `.claude/agents/agent-auditor/domains/<name>/`
- Contains at minimum a `domain.md` file

**How to verify:**
- Glob for `.claude/agents/agent-auditor/domains/<name>/**/*`
- Verify `domain.md` is among the results

**Pass/Fail:**
- PASS: Directory exists with `domain.md`
- FAIL [CRITICAL]: Directory or `domain.md` missing

### Check 1.4: Forward Slash Paths

**What to verify:**
- All file paths within domain files use forward slashes (`/`)
- No Windows backslashes (`\`) in any path references

**How to verify:**
- Read all domain files
- Scan for backslash characters in path-like strings

**Pass/Fail:**
- PASS: All paths use forward slashes
- FAIL [ERROR]: Contains backslash path separators

---

## When Complete

Record all findings with their severity levels.

Proceed to step 02: Agent Architect domain.md Quality
Read: `steps/02-architect-domain.md`
