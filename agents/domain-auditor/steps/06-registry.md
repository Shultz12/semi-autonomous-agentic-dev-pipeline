# Step 6: Registry Entry Validation

Validate that the domain is properly registered in all required registries.

## Checks to Perform

### Check 6.1: Agent Architect `_index.md` Available Domains

**What to verify:**
- The domain appears in the Available Domains table in `.claude/skills/agent-architect/domains/_index.md`

**How to verify:**
- Read `.claude/skills/agent-architect/domains/_index.md`
- Search for the domain name in the Available Domains table

**Pass/Fail:**
- PASS: Domain listed in Available Domains table
- FAIL [ERROR]: Domain not found in Agent Architect Available Domains table

### Check 6.2: Agent Architect `_index.md` Decision Matrix

**What to verify:**
- The domain appears in the Decision Matrix table in `.claude/skills/agent-architect/domains/_index.md`
- At least one row maps an agent purpose to this domain

**How to verify:**
- Search for the domain name in the Decision Matrix table

**Pass/Fail:**
- PASS: Domain appears in Decision Matrix with at least one mapping
- FAIL [WARNING]: Domain not found in Decision Matrix

### Check 6.3: Agent Auditor `_index.md` Available Domains

**What to verify:**
- The domain appears in the Available Domains table in `.claude/agents/agent-auditor/domains/_index.md`

**How to verify:**
- Read `.claude/agents/agent-auditor/domains/_index.md`
- Search for the domain name in the Available Domains table

**Pass/Fail:**
- PASS: Domain listed in Agent Auditor Available Domains table
- FAIL [ERROR]: Domain not found in Agent Auditor Available Domains table

### Check 6.4: Agent Architect SKILL.md Reference Registry

**What to verify:**
- The domain appears in the Reference Registry section of `.claude/skills/agent-architect/SKILL.md`
- Entry includes links to domain files

**How to verify:**
- Read `.claude/skills/agent-architect/SKILL.md`
- Search for the domain name in the Reference Registry section

**Pass/Fail:**
- PASS: Domain listed in SKILL.md Reference Registry
- FAIL [WARNING]: Domain not found in SKILL.md Reference Registry

---

## When Complete

Record all findings with their severity levels.

Proceed to step 07: Content Hygiene
Read: `steps/07-content-hygiene.md`
