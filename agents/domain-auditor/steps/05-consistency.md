# Step 5: Cross-System Consistency

Validate alignment between the Agent Architect domain and the Agent Auditor domain.

## Checks to Perform

### Check 5.1: Scope Descriptions Align

**What to verify:**
- The Scope section in the Agent Architect's `domain.md` and the Scope section in the Agent Auditor's `domain.md` describe the same domain purpose
- They don't contradict each other

**How to verify:**
- Read both Scope sections
- Compare the descriptions for alignment
- Flag if one describes a materially different scope than the other

**Pass/Fail:**
- PASS: Both scope descriptions are aligned and non-contradictory
- FAIL [ERROR]: Scope descriptions contradict or describe different domains

### Check 5.2: Auditable Conventions Have Checks

**What to verify:**
- Conventions defined in the Agent Architect's `domain.md` that are objectively verifiable have corresponding checks in the Agent Auditor's `domain.md`
- Not all conventions need auditor checks (some may be design guidance), but concrete verifiable ones should

**How to verify:**
- List all conventions from the Architect's `domain.md`
- For each verifiable convention, check if a corresponding auditor check exists
- Flag verifiable conventions with no auditor coverage

**Pass/Fail:**
- PASS: All verifiable conventions have corresponding auditor checks
- FAIL [WARNING]: Verifiable convention `[convention]` has no corresponding auditor check

### Check 5.3: Domain Name Consistent

**What to verify:**
- The domain name used in the Agent Architect directory matches the Agent Auditor directory
- The name referenced in the Alignment section matches both directories

**How to verify:**
- Compare directory names: `domains/<name>/` in both systems
- Check Alignment section references the same name

**Pass/Fail:**
- PASS: Domain name consistent across both systems
- FAIL [CRITICAL]: Domain name mismatch between systems

---

## When Complete

Record all findings with their severity levels.

Proceed to step 06: Registry Entry Validation
Read: `steps/06-registry.md`
