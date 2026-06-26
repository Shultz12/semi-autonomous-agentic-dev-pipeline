# log-rotator Review Report

**Reviewed:** 25.02.2026
**Type:** Sub-agent
**Domain:** Not specified

---

## FINAL VERDICT

**Overall Status:** WARNINGS

The log-rotator agent is structurally sound and follows most standards correctly. Two warnings were found: the description lacks a WHEN trigger component, and no domain is specified. The agent is ready for use after addressing these minor issues.

---

## Compliance Summary

| Category | Checks | Passed | N/A | Issues |
|----------|--------|--------|-----|--------|
| Structural | 6 | 6 | 0 | 0 |
| Core Frontmatter | 4 | 4 | 0 | 0 |
| Type Frontmatter | 4 | 3 | 0 | 1 |
| Description | 5 | 3 | 0 | 2 |
| Content Sections | 9 | 9 | 0 | 0 |
| Tools | 5 | 5 | 0 | 0 |
| Patterns | 6 | 6 | 0 | 0 |
| Domain-Specific | 0 | 0 | 0 | 0 |
| Coherence | 8 | 8 | 0 | 0 |
| Content Hygiene | 14 | 14 | 0 | 0 |
| Contract & Guide | 10 | 8 | 2 | 0 |

**Compliance Rate:** 100% (69/69 applicable checks passed, 2 N/A of 71 base)

---

## Severity Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| ERROR | 0 |
| WARNING | 3 |
| INFO | 0 |

---

## Issues & Recommendations

### WARNING: Missing WHEN component in description

**Location:** `.claude/agents/log-rotator/log-rotator.md:3`

**Issue:** The description explains what the agent does but not when to use it. This makes it harder for the orchestrator to select this agent automatically.

**Recommendation:** Append a trigger phrase to the description, e.g., "Use when log files need rotation or cleanup based on size or age thresholds."

---

### WARNING: Missing domain field in frontmatter

**Location:** `.claude/agents/log-rotator/log-rotator.md:1-6`

**Issue:** No `domain` field is specified in YAML frontmatter. Domain-specific validation was skipped.

**Recommendation:** Add `domain: dev-tooling` (or the appropriate domain) to the frontmatter to enable domain-specific validation.

---

### WARNING: No interface contract found

**Location:** `.claude/agents/interface-contracts/log-rotator.contract.md` (missing)

**Issue:** If this agent is invoked by other agents via the Agent tool, it should have an interface contract documenting its input/output format.

**Recommendation:** Create a contract file at `.claude/agents/interface-contracts/log-rotator.contract.md` with Input, Output, and Guarantees sections. If the agent is only user-invoked, this can be marked N/A.

---

## Checks Summary by Step

### Step 1: Structural Validation
- PASS 1.1 Name format (kebab-case)
- PASS 1.2 File location correct
- PASS 1.3 File name matches folder
- PASS 1.4 YAML syntax valid
- PASS 1.6 Path separators (forward slashes)
- PASS 1.7 No empty folders

### Step 2: Core Frontmatter
- PASS 2.1 Name field present and matches
- PASS 2.2 Description field present
- PASS 2.3 Model value valid
- PASS 2.4 Permission mode valid

### Step 3: Type-Specific Frontmatter
- PASS 3A.1 Tools field valid
- PASS 3A.2 Model field valid
- PASS 3A.3 Permission mode valid
- WARN 3A.4 Domain field missing

### Step 4: Description Quality
- PASS 4.1 Third person voice
- PASS 4.2 WHAT component present
- WARN 4.3 WHEN component missing
- PASS 4.4 Trigger keywords present
- PASS 4.5 Specific enough to differentiate

### Step 5: Content Sections
- PASS 5.1 Persona (H1 title)
- PASS 5.2 Mandate section
- PASS 5.3 Constraints section
- PASS 5.4 Responsibilities section
- PASS 5.5 Workflow section
- PASS 5.6 Output Format section
- N/A  5.7 Inter-Agent Communication (not applicable)
- PASS 5.8 Verification Protocol
- N/A  5.9 Codebase References

### Step 6: Tools Validation
- PASS 6.1 Tools match stated purpose
- PASS 6.2 No read-only + Write flag
- PASS 6.3 No advisory + Agent flag
- PASS 6.4 No reviewer + Bash flag
- PASS 6.5 Permission mode aligns with tools

### Step 7: Patterns Validation
- PASS 7.1 Appropriate patterns for type
- PASS 7.2 Loop guards implementation
- PASS 7.3 Tool execution verification
- PASS 7.4 File loading strategy
- PASS 7.5 Pattern file completeness
- PASS 7.6 Constraint Enforcement Hierarchy compliance

### Step 8: Coherence & Duplication
- PASS 8.1 Purpose-tools alignment
- PASS 8.2 Purpose-model alignment
- PASS 8.3 Purpose-patterns alignment
- PASS 8.4 Internal consistency
- PASS 8.5 No agent duplication
- PASS 8.6 No skill duplication
- PASS 8.7 Reference-instruction consistency
- PASS 8.8 Output persistence (self-commit)

### Step 9: Content Hygiene
- PASS 9.1 No cross-file redundancy
- PASS 9.2 No information agent can't act on
- PASS 9.3 No system-enforced constraint duplication
- PASS 9.4 No self-referential file paths
- PASS 9.5 No vague instructions with bounded equivalents
- PASS 9.6 No duplicate content across variants
- PASS 9.7 No contradictory authority claims
- PASS 9.8 No cross-boundary knowledge
- PASS 9.9 No orphaned references
- PASS 9.10 No redundant indirection
- PASS 9.11 No cross-boundary role references
- PASS 9.12 Emphasis calibration
- PASS 9.13 Constraint rationale
- PASS 9.14 Rationale discipline

### Step 10: Contract & Guide Validation
- WARN 10.1 Contract exists (not found)
- N/A  10.2 Required sections present (no contract)
- N/A  10.3 Input spec matches capabilities (no contract)
- N/A  10.4 Output spec matches output (no contract)
- N/A  10.5 No internal implementation details (no contract)
- N/A  10.6 Language and format quality (no contract)
- N/A  10.7 Multi-mode coverage (no contract)
- PASS 10.8 Guide exists
- PASS 10.9 Guide has required sections
- PASS 10.10 Guide content accuracy

### Domain-Specific Checks
No domain specified — domain checks skipped

---

**Review Complete.** This review is advisory only. The decision to proceed rests with you.
