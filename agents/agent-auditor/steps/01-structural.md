# Step 1: Structural Validation

Validate the physical structure of the agent or skill definition.

## Artifact Type Detection

First, determine what you're reviewing:
- **Sub-agent**: Located in `.claude/agents/<name>/<name>.md`
- **Skill**: Located in `.claude/skills/<agent>/<skill>/SKILL.md`

Record the artifact type - later steps will use this.

## Checks to Perform

### Check 1.1: Name Format (kebab-case)

**What to verify:**
- Name uses lowercase letters and hyphens only
- No underscores, spaces, or uppercase letters
- Pattern: `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`

**How to verify:**
- Extract name from frontmatter `name` field
- Validate against kebab-case pattern

**Pass/Fail:**
- PASS: Name matches kebab-case pattern
- FAIL [CRITICAL]: Name contains invalid characters

### Check 1.2: File Location

**What to verify:**
- Sub-agent: `.claude/agents/<name>/`
- Skill: `.claude/skills/<agent-name>/<skill-name>/`

**How to verify:**
- Check the path provided or implied in the design
- Verify it follows the correct structure for the artifact type

**Pass/Fail:**
- PASS: Path follows correct structure
- FAIL [CRITICAL]: Wrong directory structure

### Check 1.3: File Name Match

**What to verify:**
- Sub-agent: File named `<name>.md` where name matches folder name
- Skill: File named exactly `SKILL.md` (case-sensitive)

**How to verify:**
- Extract filename from path
- Compare against expected pattern

**Pass/Fail:**
- PASS: Filename matches requirements
- FAIL [CRITICAL]: Filename mismatch

### Check 1.4: YAML Frontmatter Syntax

**What to verify:**
- Frontmatter begins with `---` on first line
- Frontmatter ends with `---`
- Valid YAML syntax between delimiters

**How to verify:**
- Read the file content
- Check for proper delimiters
- Validate YAML can be parsed

**Pass/Fail:**
- PASS: Valid YAML frontmatter
- FAIL [CRITICAL]: Invalid YAML syntax or missing delimiters

### Check 1.6: Path Separators

**What to verify:**
- All paths in the document use forward slashes (`/`)
- No Windows backslashes (`\`)

**How to verify:**
- Scan document content for path references
- Check for backslash usage in paths

**Pass/Fail:**
- PASS: All paths use forward slashes
- FAIL [ERROR]: Contains backslash path separators

### Check 1.7: No Empty Folders

**What to verify:**
- Any referenced directories contain files
- No empty folders in the structure

**How to verify:**
- Check directory references in the design
- If design specifies a folder structure, verify folders have contents

**Pass/Fail:**
- PASS: No empty folders specified
- FAIL [WARNING]: Empty folders defined

---

## When Complete

Record all findings with their severity levels (CRITICAL/ERROR/WARNING).

Proceed to step 02: Core Frontmatter Validation
Read: `steps/02-core-frontmatter.md`
