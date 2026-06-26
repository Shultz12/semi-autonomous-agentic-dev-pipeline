# Step 10: Contract & Guide Validation

Validate the agent's interface contract for completeness, accuracy, and quality.

**Applicability:** Sub-agents that are invoked by other agents via the Agent tool. If the agent is standalone (user-invoked only, no inter-agent communication), report all checks as N/A.

---

## Check 10.1: Contract Exists

**What to verify:**
- An interface contract exists at one of these locations:
  - Personal: `.claude/agents/interface-contracts/<agent-name>.contract.md`
  - Project: `.claude/agents/interface-contracts/<agent-name>.contract.md`
- OR the agent is standalone and does not need one

**How to verify:**
- Check the agent's description and workflow for inter-agent communication indicators
- If the agent is spawned via Agent tool or referenced in other agents' workflows, a contract is expected
- Use Glob to check if the contract file exists at either personal or project level

**Pass/Fail:**
- PASS: Contract exists at expected path, OR agent is standalone (N/A)
- FAIL [WARNING]: Agent has inter-agent communication but no contract

## Check 10.2: Required Sections Present

**What to verify:**
- Contract contains all three required sections: Input, Output, Guarantees

**How to verify:**
- Read the contract file
- Check for H2 headers: `## Input`, `## Output`, `## Guarantees`

**Pass/Fail:**
- PASS: All three required sections present
- FAIL [ERROR]: Missing required section

## Check 10.3: Input Spec Matches Agent Capabilities

**What to verify:**
- The input specification accurately describes what the agent accepts
- Required fields in the contract match what the agent's workflow expects
- No phantom parameters that the agent does not use

**How to verify — field-by-field comparison:**
1. Read the agent's workflow Step 1 / initialization. Extract every field the agent reads from input (look for patterns like "from input", "provided in", "from the orchestrator's prompt", field names in backticks).
2. Read the contract's Input section. Extract every documented field.
3. Compare the two lists:
   - **Missing from contract:** agent expects a field not documented in the contract → FAIL
   - **Phantom in contract:** contract documents a field the agent never reads → FAIL
   - **Mode mismatch:** agent has modes (e.g., `Mode: phase-only`) not documented in contract → FAIL
4. Check field names match exactly (spelling, casing).

**Pass/Fail:**
- PASS: Every field the agent reads is documented, every documented field is consumed, all modes covered
- FAIL [ERROR]: Contract omits fields the agent requires, documents phantom fields, or misses modes

## Check 10.4: Output Spec Matches Agent Output

**What to verify:**
- The output specification matches what the agent actually produces
- All output statuses/modes are documented
- Output structure matches the agent's report/summary format

**How to verify — field-by-field comparison:**
1. Read the agent's Output Format section (or equivalent — "Step 7: Return", "Return Structured Message", etc.). Extract every field in the return message and every written file path pattern.
2. Read the contract's Output section. Extract every documented field and file path.
3. Compare the two lists:
   - **Missing from contract:** agent returns a field not documented → FAIL
   - **Phantom in contract:** contract documents a field the agent never returns → FAIL
   - **Status mismatch:** agent can return statuses (SUCCESS, BLOCKED, FAIL, etc.) not listed in contract → FAIL
   - **Written file mismatch:** agent writes to a path not documented, or contract lists a path the agent doesn't write to → FAIL
4. Check field names, status values, and path patterns match exactly.
5. If the agent writes persistent files (reports, reviews), verify the contract's "Written Report" or equivalent section matches the actual filename pattern and directory.

**Pass/Fail:**
- PASS: Every returned field is documented, every status is covered, written file paths match
- FAIL [ERROR]: Contract omits return fields, statuses, or written file paths, or documents ones that don't exist

## Check 10.5: No Internal Implementation Details

**What to verify:**
- Contract does not expose internal step files, internal state, or implementation specifics
- Only caller-relevant information is included

**How to verify:**
- Scan for references to internal files (e.g., `steps/`, internal templates)
- Check for implementation details that callers do not need

**Pass/Fail:**
- PASS: Contract contains only caller-relevant information
- FAIL [WARNING]: Contract exposes internal implementation details

## Check 10.6: Language and Format Quality

**What to verify:**
- Uses imperative language (not passive voice)
- File paths use forward slashes only
- Includes at least one example invocation
- Formatting is consistent with other contracts

**How to verify:**
- Scan for passive voice patterns ("should be provided", "is expected")
- Check all file paths for backslashes
- Look for example prompts or invocation formats
- Compare structure against existing contracts

**Pass/Fail:**
- PASS: Good language, formatting, and examples
- FAIL [WARNING]: Poor language quality, missing examples, or formatting issues

## Check 10.7: Multi-Mode Coverage

**What to verify:**
- If the agent supports multiple invocation modes, all modes are documented in the contract
- Each mode has its own input/output specification

**How to verify:**
- Identify all invocation modes from the agent's workflow
- Verify each mode appears in the contract

**Pass/Fail:**
- PASS: All modes documented, OR agent has only one mode
- FAIL [WARNING]: Agent has multiple modes but contract only documents some

## Check 10.8: Guide Exists

**What to verify:**
- A human-facing guide exists at one of these locations:
  - Personal: `.claude/documentation/<agent-name>.guide.md`
  - Project: `.claude/documentation/<agent-name>.guide.md`

**How to verify:**
- Use Glob to check if the guide file exists at either personal or project level

**Pass/Fail:**
- PASS: Guide exists at expected path (either level)
- FAIL [WARNING]: No guide found at either `.claude/documentation/` or `.claude/documentation/`

## Check 10.9: Guide Has Required Sections

**What to verify:**
- If a guide exists, it contains "What It Does" and "Related" sections (H2 headers)

**How to verify:**
- Read the guide file
- Check for H2 headers containing "What It Does" and "Related" (e.g., "Related Files", "Related Documentation")

**Pass/Fail:**
- PASS: Both sections present, OR guide doesn't exist (covered by 10.8)
- FAIL [WARNING]: Guide exists but is missing required sections

## Check 10.10: Guide Content Accuracy

**What to verify:**
- If a guide exists, its factual claims match the agent's current state
- Check counts, capability descriptions, file trees, and behavioral descriptions are accurate

**How to verify — targeted comparison:**
1. Read the guide. Extract every concrete claim:
   - Numeric counts (e.g., "67 base validation criteria", "4 checks", "5 sequential steps")
   - File trees or directory listings
   - Behavioral descriptions ("dispatches 8 agent types", "handles five statuses")
   - Domain-specific descriptions (check names, pattern lists)
2. For each numeric count: trace to the source in the agent's definition or supporting files. Verify the number matches.
3. For each file tree: Glob the agent's actual directory. Verify the tree matches (no missing files, no phantom files).
4. For each behavioral description: verify against the agent's workflow that the described behavior is current.

**Pass/Fail:**
- PASS: Guide doesn't exist (covered by 10.8), OR all factual claims are accurate
- FAIL [ERROR]: Guide states a numeric count that doesn't match the agent's actual count
- FAIL [WARNING]: Guide file tree doesn't match agent's actual directory structure
- FAIL [WARNING]: Guide describes behavior the agent no longer performs, or omits new behavior

---

## When Complete

Record all findings with their severity levels.

Proceed to step 11: Create Summary
Read: `steps/11-create-summary.md`
