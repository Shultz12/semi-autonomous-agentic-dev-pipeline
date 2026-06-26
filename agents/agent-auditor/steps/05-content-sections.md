# Step 5: Content Sections Validation

Validate that required and conditional content sections are present.

## Sub-Agent Required Sections

For sub-agents, verify these sections exist:

### Check 5.1: Persona Section (H1 Header)

**What to verify:**
- H1 header (`# Title`) exists after frontmatter
- Establishes agent identity/character

**How to verify:**
- Look for first H1 header
- Check it provides identity context

**Pass/Fail:**
- PASS: H1 persona header present
- FAIL [ERROR]: Missing persona header

### Check 5.2: Mandate Section

**What to verify:**
- Section titled "Mandate" or "## Mandate" exists
- Contains paragraph describing core purpose
- Explains what agent must achieve

**How to verify:**
- Search for "Mandate" heading
- Verify it has content describing purpose

**Pass/Fail:**
- PASS: Mandate section present with content
- FAIL [ERROR]: Missing mandate section

### Check 5.3: Core Constraints Section

**What to verify:**
- Section titled "Core Constraints" or similar exists
- Contains structured separation of prohibitions and behavioral guidelines
- Accepted structures include:
  - "Never Do" + "Always Do" subsections
  - "Safety Boundaries" + "Operating Principles" (or "Design Principles") subsections
  - Any equivalent structure that separates prohibitions from required/expected behaviors

**How to verify:**
- Search for "Constraints" heading
- Look for subsections that separate prohibitions from behavioral guidelines (e.g., "Never Do"/"Always Do", "Safety Boundaries"/"Operating Principles", or similar)

**Pass/Fail:**
- PASS: Constraints section present with structured prohibitions and behavioral guidelines
- FAIL [ERROR]: Missing constraints section
- FAIL [WARNING]: Constraints exist but lack structured separation of prohibitions and guidelines

### Check 5.4: Responsibilities Section

**What to verify:**
- Section titled "Responsibilities" exists
- Contains numbered list of agent duties
- Each item describes a specific responsibility

**How to verify:**
- Search for "Responsibilities" heading
- Verify numbered list format

**Pass/Fail:**
- PASS: Responsibilities section with numbered list
- FAIL [ERROR]: Missing responsibilities section

### Check 5.5: Workflow Section

**What to verify:**
- Section titled "Workflow" exists
- Contains phased approach (Phase 1, Phase 2, etc. OR Step 1, Step 2, etc.)
- Clear steps within each phase

**How to verify:**
- Search for "Workflow" heading
- Look for phase/step structure

**Pass/Fail:**
- PASS: Workflow section with phases/steps
- FAIL [ERROR]: Missing workflow section

---

## Conditional Sections

Check if these should be present based on agent type:

### Check 5.6: Output Format Section (if produces structured output)

**What to verify:**
- If agent produces reports, templates, or structured data
- Then "Output Format" section should exist
- Contains template or format specification

**How to detect need:**
- Mandate mentions "report", "output", "generate", "produce"
- Responsibilities include producing formatted content

**Pass/Fail:**
- PASS: Not needed OR present when needed
- FAIL [WARNING]: Produces output but no format section

### Check 5.7: Codebase References Section (if references files)

**What to verify:**
- If agent needs to consult specific files
- Then "Codebase References" section should exist
- Lists files/directories to consult

**How to detect need:**
- Workflow mentions reading specific files
- Agent needs project-specific context

**Pass/Fail:**
- PASS: Not needed OR present when needed
- FAIL [INFO]: References files but no section

### Check 5.8: Inter-Agent Communication Section (if uses handoffs)

**What to verify:**
- If agent spawns or communicates with other agents
- Then inter-agent protocol should be documented
- Handoff format specified

**How to detect need:**
- Tools include "Agent"
- Mentions spawning agents or handoffs

**Pass/Fail:**
- PASS: Not needed OR present when needed
- FAIL [WARNING]: Uses handoffs but no protocol section

### Check 5.9: Verification Protocol Section (if reviewer/validator type)

**What to verify:**
- If agent validates or reviews
- Then "Verification Protocol" section should exist
- Explains how claims are verified

**How to detect need:**
- Description mentions "review", "validate", "verify"
- Agent type is reviewer/validator

**Pass/Fail:**
- PASS: Not needed OR present when needed
- FAIL [ERROR]: Reviewer/validator without verification protocol

---

## Skill Sections

For skills, requirements are lighter:

### Check 5.10: Title (H1 Header)

**What to verify:**
- H1 header exists providing title

**Pass/Fail:**
- PASS: Title present
- FAIL [ERROR]: Missing title

### Check 5.11: Introduction

**What to verify:**
- Brief introduction explaining skill purpose

**Pass/Fail:**
- PASS: Introduction present
- FAIL [WARNING]: Missing introduction

---

## When Complete

Record all findings with their severity levels.

Proceed to step 06: Tools Validation
Read: `steps/06-tools.md`
