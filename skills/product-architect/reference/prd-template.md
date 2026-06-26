# PRD Template

Use this template when generating PRD.md. Sections §1-3 draw from Stages 1-2, sections §4-9 from Stages 3-4.

## Template

```markdown
# PRD: [Product Name]

**Status:** Draft | In Review | Approved
**Last Updated:** [date]
**Author:** [name]

## 1. Problem Statement
What problem does this product solve? Who experiences it?

### Evidence
- **User signals:** [interviews, feedback, observed behavior]
- **Market signals:** [competitive gaps, trends, regulatory changes]
- **Business signals:** [strategic alignment, revenue opportunity]

## 2. Solution Overview
What is this product? How does it solve the problem?
[1-2 paragraphs — what it IS, not detailed how]

### Differentiation
What makes this approach better than alternatives?

## 3. Target Users
| Persona | Role | Primary Need | Key Behavior |
|---------|------|-------------|--------------|
| [Name]  | ...  | ...         | ...          |

## 4. Goals & Success Metrics
| Goal | Metric | Baseline | Target | Window |
|------|--------|----------|--------|--------|
| ...  | ...    | ...      | ...    | 90 days |

## 5. Requirements
### REQ-1: [Requirement Name] (P0)
[Description]
**Acceptance criteria:** [testable conditions]

### REQ-2: [Requirement Name] (P1)
...

## 6. Non-Goals
- [What we explicitly will NOT do] — [brief rationale]
- ...

## 7. Technical Considerations
- **Dependencies:** [external services, APIs, data sources]
- **Constraints:** [performance, compliance, platform limitations]
- **Known Risks:** [technical uncertainties]

## 8. Launch Phases
| Phase | Audience | Success Gate |
|-------|----------|-------------|
| Internal Alpha | Team + design partners | No P0 bugs |
| Beta | [N] opted-in users | [metric threshold] |
| GA | All users | [metric threshold] |

## 9. Open Questions
- [Unresolved decisions that need further investigation]
```

## Field Guidance

| Section | Source Stage | Notes |
|---------|-------------|-------|
| §1 Problem Statement | Stage 1 | Evidence embedded — forces problem to be supported |
| §2 Solution Overview | Stages 1-2 | What it IS, not detailed implementation |
| §3 Target Users | Stage 2 | Table format — name, role, need, behavior |
| §4 Goals & Success Metrics | Stage 4 | Specific metrics with baselines and time windows |
| §5 Requirements | Stage 3 | REQ-# numbering, P0/P1/P2 priority, acceptance criteria |
| §6 Non-Goals | Stage 3 | Explicit exclusions with rationale |
| §7 Technical Considerations | Stage 3 | Dependencies, constraints, known risks |
| §8 Launch Phases | Stage 4 | 3-tier: Internal Alpha → Beta → GA with success gates |
| §9 Open Questions | Stage 3 | Unresolved items requiring further investigation |

## Constraints

- **P0/P1/P2 priorities** — Not RICE scoring. Simple priority tiers suffice at product level.
- **Personas as table** — Name, role, need, behavior. Not narrative personas.
- **Launch Phases simplified** — 3 tiers with success gates. Not a full GTM plan.
- **Evidence in Problem Statement** — Forces evidence to support the problem, not standalone.
- **REQ-# numbering** — Enables traceability into spec-architect's FR-# system.
