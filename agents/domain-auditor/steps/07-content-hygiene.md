# Step 7: Content Hygiene

Validate that the domain is free of content bloat, broken references, vagueness, and scope overlap.

## Check 7.1: Cross-File Redundancy

**What to verify:**
- The same information is not stated in multiple files across the domain
- No copy-pasted paragraphs or near-identical instructions between the Agent Architect and Agent Auditor domain files

**How to verify:**
- Compare content across all loaded domain files
- Look for repeated instructions, rules, or definitions
- Flag any paragraph or instruction block that appears in more than one file

**Examples of FAIL:**
- Same scope description copy-pasted verbatim in both `domain.md` files
- Convention list duplicated between Architect domain.md and a pattern file
- Same severity definitions repeated in multiple files

**Pass/Fail:**
- PASS: Each piece of information exists in exactly one file
- FAIL [WARNING]: Same content found in multiple files

### Check 7.2: Orphaned References

**What to verify:**
- All file paths mentioned in domain files point to files that actually exist
- All section references resolve to actual headings
- Pattern file links in `_index.md` resolve to existing files

**How to verify:**
- Collect all file path references from domain files
- Verify each referenced file exists
- Check section cross-references resolve to actual headings

**Examples of FAIL:**
- Domain Resources links to `patterns/_index.md` but no such file exists
- Auditor domain.md references a check step that doesn't exist
- Template link points to a deleted file

**Pass/Fail:**
- PASS: All references resolve to existing files/sections
- FAIL [ERROR]: Broken reference found: `[reference]`

### Check 7.3: Vague Instructions

**What to verify:**
- No unbounded or vague instructions where a specific, bounded equivalent exists
- Conventions and check criteria should be precise and measurable

**How to verify:**
- Scan for vague quantifiers: "thorough", "comprehensive", "carefully", "ensure quality", "best practices"
- Check if a concrete equivalent could replace the vague instruction
- Only flag when a clear bounded alternative exists

**Examples of FAIL:**
- "Ensure comprehensive coverage" without defining what comprehensive means
- "Be thorough in scanning" when specific scan commands are available
- Convention stating "follow best practices" without naming which practices

**Examples of PASS:**
- "Each convention names a concrete artifact, format, or pattern" (specific and testable)
- "All file paths use forward slashes" (specific and testable)

**Pass/Fail:**
- PASS: Instructions are specific or no bounded equivalent exists
- FAIL [WARNING]: Vague instruction has a more specific bounded equivalent

### Check 7.4: Scope Overlap With Existing Domains

**What to verify:**
- The domain's scope does not fully duplicate an existing domain's scope
- Partial overlap is acceptable if domains have clearly different focus areas

**How to verify:**
- Read all existing domain `_index.md` files
- Compare this domain's scope against each existing domain's scope
- Flag if the scope is a near-complete duplicate of an existing domain

**Pass/Fail:**
- PASS: Domain scope is distinct from existing domains (or has partial overlap with clear differentiation)
- FAIL [ERROR]: Domain scope fully overlaps with existing domain `[name]`

---

## When Complete

Record all findings with their severity levels.

Proceed to step 08: Self-Check Findings
Read: `steps/08-self-check.md`
