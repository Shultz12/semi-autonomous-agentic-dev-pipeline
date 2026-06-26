# Step 3: Pattern & Template Validation

Validate the domain's pattern library and any templates.

## Checks to Perform

### Check 3.1: Pattern Index Exists

**What to verify:**
- `patterns/_index.md` exists at `.claude/skills/agent-architect/domains/<name>/patterns/_index.md`

**How to verify:**
- Glob for the file
- If no patterns directory exists at all, report all pattern checks as ⬜ N/A

**Pass/Fail:**
- PASS: `patterns/_index.md` exists
- FAIL [ERROR]: Pattern index missing but pattern files exist
- ⬜ N/A: No patterns directory exists (domain has no patterns)

### Check 3.2: Available Patterns Table

**What to verify:**
- `_index.md` contains an `## Available Patterns` section
- Table lists all pattern files with Pattern name, Purpose, and File link columns

**How to verify:**
- Read `_index.md`
- Search for the Available Patterns table
- Verify table has the expected columns

**Pass/Fail:**
- PASS: Available Patterns table present and complete
- FAIL [ERROR]: Table missing or missing columns

### Check 3.3: Pattern Selection Guide

**What to verify:**
- `_index.md` contains a `## Pattern Selection Guide` section
- Table maps agent types to recommended patterns

**How to verify:**
- Search for Pattern Selection Guide heading and table

**Pass/Fail:**
- PASS: Pattern Selection Guide table present
- FAIL [WARNING]: Pattern Selection Guide missing

### Check 3.4: Pattern File Required Sections

**What to verify:**
- Each pattern file has these sections: Purpose, When to Apply, Implementation, Rationale

**How to verify:**
- Read each pattern file found in the patterns directory
- Check for the four required section headings

**Pass/Fail:**
- PASS: All pattern files have all four required sections
- FAIL [ERROR]: Pattern `[filename]` missing section: `[section name]`

### Check 3.5: No Orphaned Patterns

**What to verify:**
- Every pattern file in the directory is listed in `_index.md`'s Available Patterns table
- Every entry in the Available Patterns table resolves to an existing file

**How to verify:**
- Glob all `.md` files in the patterns directory (excluding `_index.md`)
- Compare against entries in the Available Patterns table
- Flag mismatches in either direction

**Pass/Fail:**
- PASS: Pattern files and index entries match exactly
- FAIL [ERROR]: Orphaned pattern — file `[name]` exists but not listed in index
- FAIL [ERROR]: Missing pattern — `[name]` listed in index but file not found

### Check 3.6: Template File Structure

**What to verify:**
- If template files exist (in a `templates/` directory), they have valid structure
- Templates should be well-formed markdown with clear placeholders

**How to verify:**
- Glob for template files in the domain directory
- If found, verify they have reasonable structure (headings, content)

**Pass/Fail:**
- PASS: Template files are well-structured
- FAIL [WARNING]: Template `[filename]` has structural issues
- ⬜ N/A: No template files exist

### Check 3.7: Templates Referenced in Domain Resources

**What to verify:**
- If template files exist, they are linked in the Domain Resources section of `domain.md`

**How to verify:**
- If templates were found in check 3.6, verify Domain Resources section links to them

**Pass/Fail:**
- PASS: Templates are referenced in Domain Resources
- FAIL [WARNING]: Template exists but not referenced in Domain Resources
- ⬜ N/A: No template files exist

---

## When Complete

Record all findings with their severity levels.

Proceed to step 04: Agent Auditor domain.md Quality
Read: `steps/04-auditor-domain.md`
