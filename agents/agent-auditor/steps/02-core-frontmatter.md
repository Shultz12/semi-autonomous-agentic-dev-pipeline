# Step 2: Core Frontmatter Validation

Validate the common frontmatter fields required for both sub-agents and skills.

## Checks to Perform

### Check 2.1: Name Field Present and Matches

**What to verify:**
- `name` field exists in frontmatter
- Value matches the folder name and file name (for sub-agents)
- Value matches the skill folder name (for skills)

**How to verify:**
- Parse frontmatter
- Compare `name` value against path components

**Pass/Fail:**
- PASS: `name` present and matches
- FAIL [CRITICAL]: `name` missing
- FAIL [ERROR]: `name` doesn't match folder/file name

### Check 2.2: Description Field Present

**What to verify:**
- `description` field exists
- Value is non-empty string
- Value is not placeholder text

**How to verify:**
- Parse frontmatter
- Check `description` value exists and has content

**Pass/Fail:**
- PASS: Description present and non-empty
- FAIL [CRITICAL]: Description missing or empty

### Check 2.3: Model Field Valid (if present)

**What to verify:**
- If `model` field exists, it has a valid value
- Valid values: `haiku`, `sonnet`, `opus`, `inherit`

**How to verify:**
- Parse frontmatter
- If `model` exists, validate against allowed values

**Pass/Fail:**
- PASS: Model absent (defaults to inherit) or valid value
- FAIL [ERROR]: Invalid model value

### Check 2.4: Permission Mode Valid (if present)

**What to verify:**
- If `permissionMode` field exists, it has a valid value
- Valid values: `default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`

**How to verify:**
- Parse frontmatter
- If `permissionMode` exists, validate against allowed values

**Pass/Fail:**
- PASS: Permission mode absent or valid value
- FAIL [ERROR]: Invalid permission mode value

---

## When Complete

Record all findings with their severity levels.

Proceed to step 03: Type-Specific Frontmatter Validation
Read: `steps/03-type-frontmatter.md`
