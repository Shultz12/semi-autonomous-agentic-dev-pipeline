# SDD Template

Strict template for Software Design Documents. Follow this structure exactly.

---

# Software Design Document: [Feature Name]

## Meta

- **Feature:** [feature-name]
- **Source Spec:** `[feature-dir]/specs/SRS.md`
- **Created:** [YYYY-MM-DD]
- **Design Confidence:** [High | Medium | Low]

---

## Design Overview

[1-2 paragraph summary of the architectural approach and key design philosophy. What pattern does this follow? Why this approach over others?]

---

## Component Architecture

| Component | Responsibility | Layer | Implements |
|-----------|---------------|-------|------------|
| [Name] | [What it does] | [architecture layer] | FR-X (SRS.md:L##), FR-Y (SRS.md:L##) |

---

## Design Decisions

### DD-1: [Decision Title]

- **Context:** [Forces at play — what requirement drives this + what the codebase exploration found]
- **Requirements:** FR-X (SRS.md:L##), FR-Y (SRS.md:L##)
- **Decision:** [What was chosen]
- **Rationale:** [Why — including codebase evidence with file:line references]
- **Alternatives Rejected:** [What was considered and why not]
- **Consequences:** [Positive and negative implications]

### DD-2: [Decision Title]

[Same structure as DD-1]

[Additional DD-# as needed]

---

## Interface Contracts

### [Component A] → [Component B]

- **Method/Event:** [signature or event name]
- **Input:** [DTO or parameter description]
- **Output:** [Return type or event payload]
- **Error cases:** [What can go wrong]

[Additional interfaces as needed]

---

## Data Flow

[How data moves through the system for primary operations. Key state transitions. Can use a textual diagram or description.]

---

## Data Model

[Schema overview — entities, key relations, relevant to this feature only. Not a full schema dump.]

---

## Integration Points

| Existing Component | File Location | How New Code Integrates |
|-------------------|---------------|------------------------|
| [Name] | `path/to/file.ts:lines` | [Description of integration] |

---

## Constraints & Boundaries

- **In scope:** [What this design handles]
- **Out of scope:** [What this design explicitly does NOT handle]
- **Accepted limitations:** [Known tradeoffs the user agreed to]

---

## Requirement Traceability

| Requirement | SRS Location | Component | Design Decision |
|-------------|-------------|-----------|-----------------|
| FR-1: [name] | SRS.md:L## | [Component] | DD-# |
| FR-2: [name] | SRS.md:L## | [Component] | DD-# |

[Every SRS functional requirement must appear in this table.]
