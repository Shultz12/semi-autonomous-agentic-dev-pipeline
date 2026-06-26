# Domain: agent-tooling

## Scope

Agents and skills that create, update, audit, and maintain other agents, skills, domains, and their supporting files. Includes architects (interactive), auditors (validators), and meta-orchestrators.

---

## Domain Checks

Checks are numbered by the base step they extend: `<step>.D<n>`.

### Step 1 Extensions: Structural

#### Check 1.D1: Internal File Organization

**What to verify:**
- Multi-file agents use subdirectories (essentials/, modes/, steps/, references/ as applicable)
- No loose reference files dumped in the agent's root alongside the main definition

**Pass/Fail:**
- PASS: Files organized into appropriate subdirectories
- FAIL [WARNING]: Flat structure with multiple loose files

### Step 5 Extensions: Content

#### Check 5.D1: Summary Format Definition

**What to verify:**
- Architect agents reference or include a summary format definition
- Summary is displayed at the start of every response (instruction present)

**Pass/Fail:**
- PASS: Summary format defined and display instruction present
- FAIL [ERROR]: Architect agent missing summary format

#### Check 5.D2: Mode Routing Logic

**What to verify:**
- Interactive agents parse operation mode from invocation arguments
- Fallback to a selection prompt when arguments are ambiguous

**Pass/Fail:**
- PASS: Mode routing with argument parsing and fallback documented
- FAIL [WARNING]: No mode routing or missing fallback

#### Check 5.D3: Worked Examples

**What to verify:**
- At least one complete worked example per major workflow
- Examples in examples/ directory or inline in documentation

**Pass/Fail:**
- PASS: Worked examples present for each major workflow
- FAIL [WARNING]: Missing worked examples

#### Check 5.D4: Contrastive Examples

**What to verify:**
- Convention/rule definitions include GOOD vs BAD examples
- Examples have concrete explanations of what passes and what fails

**Pass/Fail:**
- PASS: Contrastive examples present where rules are defined
- FAIL [WARNING]: Rules defined without contrastive examples

### Step 7 Extensions: Behavioral Patterns

#### Check 7.D1: Review Integration

**What to verify:**
- Architect agents include instructions to offer auditor review after creation
- Auditor is spawned via Agent tool, not auto-invoked

**Pass/Fail:**
- PASS: Review integration documented with user-permission gate
- FAIL [WARNING]: Architect agent missing review integration

#### Check 7.D2: Central Standards File

**What to verify:**
- Auditor agents reference a central standards file
- Standards file defines severity levels (CRITICAL/ERROR/WARNING/INFO)
- Pass/fail criteria documented

**Pass/Fail:**
- PASS: Central standards file with severity definitions and pass/fail criteria
- FAIL [ERROR]: Auditor agent missing standards file or severity definitions

#### Check 7.D3: Dual-Output Protocol

**What to verify:**
- Auditor agents document both outputs: handoff file + direct return summary
- Both outputs carry the same verdict

**Pass/Fail:**
- PASS: Dual-output protocol documented with consistent verdict requirement
- FAIL [ERROR]: Missing dual-output documentation or only one output defined

#### Check 7.D4: Step-Based Sequential Workflow

**What to verify:**
- Auditor agents have a `steps/` directory with sequentially numbered files (`01-*.md`, `02-*.md`, etc.)
- Step numbering is contiguous (no gaps)

**Pass/Fail:**
- PASS: `steps/` directory present with sequentially numbered files
- FAIL [WARNING]: Auditor agent missing `steps/` directory or non-sequential numbering

#### Check 7.D5: Interface Contracts for Outputs

**What to verify:**
- Agent-spawnable agents produced by agent-tooling agents have corresponding interface contracts at `.claude/agents/interface-contracts/<name>.contract.md`

**Pass/Fail:**
- PASS: Interface contract exists for each Agent-spawnable agent output
- FAIL [WARNING]: Agent-spawnable agent lacks an interface contract

#### Check 7.D6: Self-Verification Loop Implementation

**What to verify:**
- If agent is an auditor or validator type that produces structured reports
- Self-verification loop should be implemented with bounded iteration
- Maximum retry limit must be explicit (typically 3)
- Fallback behavior defined for when max iterations exceeded

**Implementation markers:**
- Verification checklist applied to own output after generation
- Explicit iteration bound (e.g., "max 3 attempts", "maximum 3 iterations")
- Fix-and-re-verify cycle documented
- Fallback on exhaustion (e.g., "report incomplete items and proceed")

**Pass/Fail:**
- PASS: Not an auditor/validator, OR self-verification loop with bounded iteration
- FAIL [WARNING]: Auditor/validator agent without self-verification loop
- FAIL [WARNING]: Self-verification loop present but missing explicit iteration bound or fallback

### Step 9 Extensions: Registry Coordination

#### Check 9.D1: Registry Update Instructions

**What to verify:**
- Agents that manage registries specify which registries to update
- Update order documented (for atomicity)

**Pass/Fail:**
- PASS: Registry update targets and order documented
- FAIL [WARNING]: Manages registries without specifying update targets

---

## Additional Checklist Count

**12 additional checks** (1.D1, 5.D1, 5.D2, 5.D3, 5.D4, 7.D1, 7.D2, 7.D3, 7.D4, 7.D5, 7.D6, 9.D1)

---

## Alignment

Domain name `agent-tooling` aligns with Agent Architect's agent-tooling domain.
