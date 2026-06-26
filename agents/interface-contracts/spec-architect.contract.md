# spec-architect Interface Contract

## Input

Provide the feature name. A spec is whole-feature; spec-architect infers which layers it touches.

**Required field in prompt:**
```
Feature: [feature-name]
```

**Expected state:**
- Project has a `CLAUDE.md` with conventions and constraints
- `.project/product/PRD.md` exists (optional — enriches questioning if present)

### Example Invocation

```
Feature: credit-system
```

The skill creates the feature directory automatically at `.project/cycles/DD-MM-YYYY-[feature-name]/specs/`.

## Output

### Output Files

| File | Path | Required |
|------|------|----------|
| SRS | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/SRS.md` | Yes |
| BDD Context | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/CONTEXT.md` | Yes |
| Primary Feature | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/[feature-name].feature` | Yes |
| Error Scenarios | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/[feature-name]-errors.feature` | No |
| Edge Cases | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/[feature-name]-edge-cases.feature` | No |
| Checklist | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/IMPLEMENTATION_CHECKLIST.md` | No |

`IMPLEMENTATION_CHECKLIST.md` is a human-readable reference only. No downstream agent reads or consumes it.

### SRS Structure

**Frontmatter (all fields required):**

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Semantic version (e.g., `"1.0.0"`) |
| `status` | string | Document status (e.g., `draft`, `approved`) |
| `project` | string | Project name |
| `feature` | string | Feature name — used by design-architect and spec-auditor to identify the feature |
| `active-layers` | array | Layers the feature touches — items from `backend`, `frontend`, `infrastructure`. Used by spec-auditor for conditional-section gating. |
| `related-specs` | array | List of related spec paths (may be empty) |
| `created` | string | ISO date (`YYYY-MM-DD`) |
| `updated` | string | ISO date (`YYYY-MM-DD`) |

**Section structure (12 numbered sections):**

| # | Section | Key Structural Elements |
|---|---------|------------------------|
| 1 | Objective | Goal (one sentence), Success Criteria (checklist) |
| 2 | Context & Constraints | Business Context, Technical Context, Constraints, Scope Boundaries |
| 3 | Tech Stack | Backend, Frontend, Infrastructure subsections (per active layer) |
| 4 | Architecture & Data Flow | Layer Assignments, Data Flow Diagram, API Contracts, Data Models, UI Components |
| 5 | Functional Requirements | FR-X numbered requirements (see format below) |
| 6 | Non-Functional Requirements | NFR-X numbered requirements across subsections (see format below) |
| 7 | Boundaries | ALWAYS (safe assumptions), ASK FIRST (requires approval), NEVER (hard stops) |
| 8 | Commands | Development & Database Commands, Testing This Feature |
| 9 | References | File Paths to Study, Related Documentation, BDD Specifications |
| 10 | Implementation Checklist | Phased checklist (Setup, Backend, Frontend, Integration, Documentation) |
| 11 | Open Questions | Numbered questions with options and recommendations |
| 12 | Change Log | Date, Version, Author, Changes table |

**FR-X format:**
```
### FR-X: [Requirement Name] (P0|P1|P2)
```
Each FR-X contains: User Story, Acceptance Criteria, Implementation Notes, Edge Cases, Test Cases, Defense-in-Depth Validation. IDs are sequential starting at FR-1.

**NFR-X format:**
```
#### NFR-X: [Requirement Name] (P0|P1|P2)
```
NFR-X IDs are sequential across all Section 6 subsections (Performance, Security, Accessibility, Scalability, Localization). Numbering does not restart per subsection.

### BDD Context Structure (CONTEXT.md)

All sections are required:

| Section | Contents |
|---------|----------|
| Domain Language | Table with Term, Definition, Technical Mapping columns |
| Actors | Table with Actor, Description, Permissions columns |
| Technical Context | Architecture Layer, Key Files, Existing Utilities, Database Models, Dependencies |
| Implementation Mapping | Table with Step, Code Equivalent columns mapping Gherkin steps to code |
| Data Fixtures | Test Users, Test Documents, Sample Data, Edge Cases |
| Error Codes Reference | Table with Code, User Message, Scenario columns |

### Feature File Structure (.feature)

**Feature-level tags (all required):**
- `@domain:[module-name]`
- `@priority:P0|P1|P2`
- `@layer:[architecture-layer]`

**Feature description:**
```gherkin
Feature: [Feature Name]
  As a [actor]
  I want [capability]
  So that [business value]
```

**Background section** precedes all scenarios with common setup.

**Scenario tags:**
- `@happy-path` — successful flows
- `@edge-case` — boundary conditions
- `@error-handling` — failure scenarios
- `@defense-in-depth` — multi-layer validation

**File priority for downstream consumers:**

| Priority | File | Consumer Use |
|----------|------|-------------|
| Primary | `[feature-name].feature` | Core happy-path journeys. design-architect uses for primary requirement extraction. plan-architect structures core phases from these. |
| Secondary | `[feature-name]-errors.feature` | Error handling and defensive validation tasks. |
| Tertiary | `[feature-name]-edge-cases.feature` | Robustness tasks, addressed after core implementation. |

### Completion Summary

On success, spec-architect returns:

```
## Specification Complete

Generated Files:
- .project/cycles/DD-MM-YYYY-[feature-name]/specs/SRS.md
- .project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/CONTEXT.md
- .project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/[feature-name].feature
- [optional files if generated]

Next Steps:
1. Review specifications for accuracy
2. Run spec-auditor to validate
3. Run /design-architect [feature-name] to create SDD
4. Run plan-architect to generate implementation plan
```

## Guarantees

- SRS always contains all 8 required frontmatter fields
- SRS always contains 12 numbered sections in the order specified above
- FR-X IDs are sequential starting at FR-1, each with a P0/P1/P2 priority tag
- NFR-X IDs are sequential across all Section 6 subsections, each with a P0/P1/P2 priority tag
- FR-X headers use `###` level; NFR-X headers use `####` level
- The `feature` frontmatter field matches the feature name used in file paths
- CONTEXT.md always contains all 6 required sections
- Primary `.feature` file always has `@domain`, `@priority`, and `@layer` tags at feature level
- Every scenario has at least one tag from: `@happy-path`, `@edge-case`, `@error-handling`, `@defense-in-depth`
- Feature files use business language, not technical jargon (no HTTP codes, no function names in steps)
- The three required output files (SRS.md, CONTEXT.md, primary .feature) are always generated; optional files are generated only when applicable
- File paths in SRS Section 9 reference actual codebase files discovered during exploration
- Output directory structure is always `.project/cycles/DD-MM-YYYY-[feature-name]/specs/` with `bdd/` subdirectory
- Date in directory name uses DD-MM-YYYY format
