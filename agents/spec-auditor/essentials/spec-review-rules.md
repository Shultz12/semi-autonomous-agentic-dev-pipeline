# Spec Review Rules

Validation rules for SRS and BDD documents produced by spec-architect. These rules define what constitutes a structurally valid specification.

## Reviewer Posture

Apply these rules like an adversarial auditor: strict, by-the-book, and actively hunting for defects rather than rationalizing specs into compliance. Default to doubt. If a rule could plausibly apply and you have not verified the document against it, check it. Borderline findings get surfaced, not absorbed on the author's behalf. Rigor here means every loaded rule gets checked against every spec file — it does not mean inventing issues the specs do not actually contain, and it does not mean inflating severities beyond what this rulebook specifies.

### Evidence Standards

Every finding carries a Confidence value. The review workflow drops anything below MEDIUM.

| Confidence | Evidence | Example |
|-----------|----------|---------|
| **HIGH** | Direct quote from the spec that exhibits the defect, or an explicit cross-reference gap shown by Read / Grep | FR-3 heading exists but no `**Acceptance Criteria:**` subsection found under it (Grep returned zero matches) |
| **MEDIUM** | Structural or pattern-level mismatch inferred from sibling sections | FR-1 and FR-2 both have `**User Story:**` subsections; FR-3 does not |
| **LOW (drop)** | Interpretive taste calls — "this requirement feels too general", "this scenario seems thin" | Re-investigate once; if no HIGH/MEDIUM evidence surfaces, drop the finding |

## SRS Structure Rules

### Frontmatter Fields (Required)

| Field | Valid Values | Severity if Missing |
|-------|-------------|---------------------|
| version | Semantic version (e.g., "1.0.0") | ERROR |
| status | Any string | WARNING |
| project | Any string | WARNING |
| feature | Any string | ERROR |
| active-layers | non-empty list; items ∈ backend, frontend, infrastructure | ERROR |
| created | Date string | WARNING |
| updated | Date string | WARNING |

### Required Sections (All specs)

These sections must always be present with non-empty content:

| Section | Heading Pattern | Severity if Missing |
|---------|----------------|---------------------|
| Objective | `## 1. Objective` | CRITICAL |
| Context & Constraints | `## 2. Context & Constraints` | CRITICAL |
| Functional Requirements | `## 5. Functional Requirements` | CRITICAL |
| Non-Functional Requirements | `## 6. Non-Functional Requirements` | ERROR |
| Boundaries | `## 7. Boundaries` | ERROR |
| References | `## 9. References` | WARNING |

### Conditional Sections (Based on active-layers)

Read the `active-layers` list from SRS frontmatter. A section is required when its layer is a member of the list:

| Section | Required When | Severity if Missing |
|---------|--------------|---------------------|
| `### 3.1 Backend` | `backend` ∈ active-layers | WARNING |
| `### 3.2 Frontend` | `frontend` ∈ active-layers | WARNING |
| `### 3.3 Infrastructure` | `infrastructure` ∈ active-layers | WARNING |
| `### 4.1 Layer Assignments` | `backend` ∈ active-layers | WARNING |
| `### 4.3 API Contracts` | `backend` ∈ active-layers | WARNING |
| `### 4.5 UI Components` | `frontend` ∈ active-layers | WARNING |

### Optional Sections (INFO if missing)

| Section | Heading Pattern |
|---------|----------------|
| Tech Stack | `## 3. Tech Stack` |
| Commands | `## 8. Commands` |
| Implementation Checklist | `## 10. Implementation Checklist` |
| Open Questions | `## 11. Open Questions` |
| Change Log | `## 12. Change Log` |

## Functional Requirement Rules

### FR-X ID Format

- Each functional requirement must use the heading pattern: `### FR-X: [Name] (P0|P1|P2)`
- X must be a positive integer (FR-1, FR-2, FR-3...)
- IDs must be sequential (no gaps: FR-1, FR-3 without FR-2 is an ERROR)
- Priority must be one of: P0, P1, P2
- At least one FR-X must exist (zero functional requirements is CRITICAL)

### Per-Requirement Quality

Each FR-X section must contain:

| Element | Detection Method | Severity if Missing |
|---------|-----------------|---------------------|
| Acceptance Criteria | Grep for `**Acceptance Criteria:**` or `- [ ]` items under FR-X | ERROR |
| User Story | Grep for `**User Story:**` or `As a ... I want ... So that` | WARNING |
| Edge Cases | Grep for `**Edge Cases:**` or edge case table | WARNING |

## Non-Functional Requirement Rules

Section 6 must contain at least one populated subsection. Check for these headings:

| Subsection | Heading Pattern |
|------------|----------------|
| Performance | `### 6.1 Performance` |
| Security | `### 6.2 Security` |
| Accessibility | `### 6.3 Accessibility` |
| Scalability | `### 6.4 Scalability` |
| Localization | `### 6.5 Localization` |

- At least one subsection present: ERROR if none
- Each present subsection must have non-empty content: WARNING if empty

## BDD Structure Rules

### Required Files

| File | Path Pattern | Severity if Missing |
|------|-------------|---------------------|
| CONTEXT.md | `<specs-dir>/bdd/CONTEXT.md` | ERROR |
| Primary .feature | `<specs-dir>/bdd/<feature-name>.feature` | ERROR |

### Optional Files (INFO if missing)

| File | Path Pattern |
|------|-------------|
| Error scenarios | `<specs-dir>/bdd/<feature-name>-errors.feature` |
| Edge cases | `<specs-dir>/bdd/<feature-name>-edge-cases.feature` |

### CONTEXT.md Required Sections

| Section | Detection Pattern | Severity if Missing |
|---------|------------------|---------------------|
| Domain Language | `## Domain Language` | ERROR |
| Actors | `## Actors` | ERROR |
| Technical Context | `## Technical Context` | WARNING |
| Implementation Mapping | `## Implementation Mapping` | WARNING |
| Data Fixtures | `## Data Fixtures` | WARNING |
| Error Codes Reference | `## Error Codes Reference` | WARNING |

### .feature File Structure

| Element | Detection Pattern | Severity if Missing |
|---------|------------------|---------------------|
| Feature-level tags | `@domain:` and `@priority:` and `@layer:` on first line | ERROR |
| Feature declaration | `Feature:` keyword | CRITICAL |
| At least one Scenario | `Scenario:` or `Scenario Outline:` | ERROR |
| Scenario tags | `@happy-path`, `@error-handling`, `@edge-case`, or `@defense-in-depth` | WARNING |

### Gherkin Syntax (via gherkin-lint)

Run `npx gherkin-lint <file>` on each .feature file.
- If gherkin-lint exits with errors: report each error as ERROR
- If gherkin-lint is not installed (command not found): report WARNING and skip

## Vague Language Rules

Scan SRS functional requirements (Section 5) and acceptance criteria for vague terms:

| Pattern | Severity |
|---------|----------|
| "should be fast" / "quickly" / "fast" (without quantification) | WARNING |
| "user-friendly" / "intuitive" / "easy" / "simple" | WARNING |
| "etc." / "and so on" / "and more" | WARNING |
| "various" / "appropriate" / "reasonable" | WARNING |
| "as needed" / "when necessary" (without defining when) | WARNING |
| "some" / "several" / "a few" (without quantification) | WARNING |

Vague language in Section 6 (Non-Functional Requirements) is also flagged but only if the term appears without a quantified alternative nearby (e.g., "fast" is fine if followed by "p50: 100ms").

## Traceability Rules

### SRS → BDD Coverage

For each FR-X in the SRS:
1. Extract the requirement name from the heading (e.g., FR-1: "Assign Task to Team Member")
2. Extract key domain terms from the name and acceptance criteria
3. Search all .feature files for those domain terms
4. If no plausible scenario found: WARNING ("FR-X may lack BDD coverage — no scenario mentions [key terms]")

This is a heuristic check. BDD scenarios use business language and do not reference FR-X IDs directly. False positives are possible when scenarios use different phrasing — severity is WARNING, not ERROR.
