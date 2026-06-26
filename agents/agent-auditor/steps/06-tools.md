# Step 6: Tools Validation

Validate that tool assignments match the agent's stated purpose and detect red flags.

## Purpose Analysis

First, categorize the agent's purpose by analyzing:
- Description text
- Mandate section
- Responsibilities

**Purpose Categories:**
| Keywords Found | Category |
|----------------|----------|
| review, validate, check, analyze, audit | Read-only / Reviewer |
| create, implement, build, fix, write, develop | Developer / Architect |
| explore, research, search, find, discover | Explorer |
| coordinate, orchestrate, manage, pipeline | Orchestrator |
| plan, design, architect | Planner |

## Checks to Perform

### Check 6.1: Tools Match Purpose

**What to verify:**
- Tools assigned align with the purpose category

**Expected alignment:**
| Purpose | Expected Tools |
|---------|----------------|
| Read-only / Reviewer | Read, Grep, Glob (NO Write, Edit, Bash) |
| Developer / Architect | Read, Edit, Write, Bash, Grep, Glob |
| Explorer | Read, Grep, Glob, WebSearch, WebFetch |
| Orchestrator | Agent, Read + purpose-specific tools |
| Planner | Read, Grep, Glob (plan mode) |

**How to verify:**
- Identify purpose category
- Compare assigned tools against expected set

**Pass/Fail:**
- PASS: Tools align with purpose
- FAIL [WARNING]: Unexpected tools for purpose (investigate justification)

### Check 6.2: Red Flag - Read-Only with Write Tools

**What to verify:**
- If purpose is read-only (review, validate, analyze)
- Agent should NOT have Write or Edit tools

**How to verify:**
- Check if purpose is read-only
- Check if tools include Write or Edit

**Pass/Fail:**
- PASS: Read-only without write tools
- FAIL [ERROR]: Read-only purpose but has Write/Edit tools

### Check 6.3: Red Flag - Advisory with Agent Tool

**What to verify:**
- If agent is advisory (cannot block, recommends only)
- Should NOT have Agent tool (can spawn sub-agents)

**How to verify:**
- Check if agent is advisory type
- Check if tools include Agent

**Pass/Fail:**
- PASS: Advisory without Agent tool
- FAIL [WARNING]: Advisory agent has Agent tool - verify this is intentional

### Check 6.4: Red Flag - Reviewer with Bash

**What to verify:**
- If agent is a reviewer type
- Bash access should be justified (e.g., for running linters, tests)

**How to verify:**
- Check if agent is reviewer type
- If Bash present, check for justification in workflow

**Pass/Fail:**
- PASS: No Bash OR Bash justified in workflow
- FAIL [WARNING]: Reviewer has Bash without clear justification

### Check 6.5: Permission Mode Alignment

**What to verify:**
- Permission mode matches the risk level of tools

**Expected alignment:**
| Permission Mode | Appropriate For |
|-----------------|-----------------|
| plan | Read-only exploration |
| default | Standard operations |
| acceptEdits | Trusted code modifications |
| bypassPermissions | Highly trusted automation |

**How to verify:**
- Check permission mode
- Verify it matches tool risk level

**Pass/Fail:**
- PASS: Permission mode appropriate for tools
- FAIL [WARNING]: Permission mode may be too permissive for tools

---

## When Complete

Record all findings with their severity levels.

Proceed to step 07: Patterns Validation
Read: `steps/07-patterns.md`
