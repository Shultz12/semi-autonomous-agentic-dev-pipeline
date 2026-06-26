# Step 4: Agent Auditor domain.md Quality

Validate the Agent Auditor's domain definition file at `.claude/agents/agent-auditor/domains/<name>/domain.md`.

## Checks to Perform

### Check 4.1: Scope Section Present

**What to verify:**
- A `## Scope` section exists
- Contains a description of what this domain covers

**How to verify:**
- Search for `## Scope` heading in the file
- Verify content follows

**Pass/Fail:**
- PASS: Scope section present with description
- FAIL [ERROR]: Scope section missing

### Check 4.2: Domain Checks Section Present

**What to verify:**
- A `## Domain Checks` section exists
- Contains at least one check definition with ID, verification criteria, and pass/fail

**How to verify:**
- Search for `## Domain Checks` heading
- Verify check definitions follow with proper structure

**Pass/Fail:**
- PASS: Domain Checks section present with check definitions
- FAIL [ERROR]: Domain Checks section missing or empty

### Check 4.3: Check ID Format

**What to verify:**
- All check IDs follow the `<step>.D<n>` format
- Step number is a valid base step number
- D-number is sequential within each step group

**How to verify:**
- Extract all check IDs from the file
- Validate each against the pattern `\d+\.D\d+`
- Verify no conflicts with base check IDs (base checks use `<step>.<n>` format)

**Pass/Fail:**
- PASS: All check IDs follow `<step>.D<n>` format
- FAIL [ERROR]: Check ID `[id]` does not follow required format

### Check 4.4: Check Quality

**What to verify:**
- Each check has a concrete "What to verify" section with specific items
- Each check has unambiguous "Pass/Fail" criteria
- Criteria are not subjective or circular

**How to verify:**
- Read each check definition
- Verify "What to verify" lists specific, inspectable items
- Verify "Pass/Fail" conditions are unambiguous

**Pass/Fail:**
- PASS: All checks have concrete verification and pass/fail criteria
- FAIL [ERROR]: Check `[id]` has vague or missing pass/fail criteria

### Check 4.5: Additional Checklist Count Accuracy

**What to verify:**
- The `## Additional Checklist Count` section declares a check count
- The declared count matches the actual number of checks defined in the file

**How to verify:**
- Find the Additional Checklist Count section
- Count the actual check definitions in the file
- Compare declared vs actual

**Pass/Fail:**
- PASS: Declared count matches actual count
- FAIL [ERROR]: Declared count `[n]` but found `[m]` actual checks

### Check 4.6: Alignment Section Present

**What to verify:**
- An `## Alignment` section exists
- References the correct domain name matching the Agent Architect domain

**How to verify:**
- Search for `## Alignment` heading
- Verify the domain name mentioned matches the domain being reviewed

**Pass/Fail:**
- PASS: Alignment section present with correct domain name
- FAIL [WARNING]: Alignment section missing or references wrong domain name

---

## When Complete

Record all findings with their severity levels.

Proceed to step 05: Cross-System Consistency
Read: `steps/05-consistency.md`
