# product-architect Interface Contract

## Input

Product-architect is user-invoked only (`/product-architect [create|update]`). It is not spawned by other agents.

### Invocation Modes

| Mode | Argument | Preconditions | Behavior |
|------|----------|---------------|----------|
| Create | `create` or no argument (when no VISION.md exists) | None | Generates all output files from scratch via progressive questioning |
| Update | `update` or no argument (when VISION.md exists, user confirms update) | Existing `.project/product/VISION.md`, `.project/product/PRD.md` | Reads existing documents, re-questions affected areas, preserves unchanged sections |

### Example Invocations

```
/product-architect
/product-architect create
/product-architect update
```

No other agent invokes product-architect directly. This contract documents the **output file formats** that downstream agents consume.

## Output

Product-architect writes 2 files to `.project/product/`, and delegates the ROADMAP to `progress-tracker`:

| File | Location | Persistence |
|------|----------|-------------|
| VISION.md | `.project/product/VISION.md` | Persistent — rarely changes |
| PRD.md | `.project/product/PRD.md` | Persistent — evolves with product |

Product-architect does **not** write `.project/product/ROADMAP.md`. After Stage 5 it dispatches `progress-tracker` in `init` mode (via the Agent tool), handing off the North Star, milestones (version, description, status, success criteria), per-milestone feature backlog, and "What We're Not Building" rows. `progress-tracker` owns the ROADMAP file — its creation and every later transition. See `progress-tracker.contract.md` for the `init` input shape.

### PRD.md Structure

Consumed by: **spec-architect** (optional product context)

| Section | Content | Downstream Use |
|---------|---------|---------------|
| §1 Problem Statement | Problem + Evidence (user/market/business signals) | Product context for feature scoping |
| §2 Solution Overview | What the product is + Differentiation | Product context |
| §3 Target Users | Persona table (Name, Role, Need, Behavior) | User context for feature requirements |
| §4 Goals & Success Metrics | Metrics table (Goal, Metric, Baseline, Target, Window) | Acceptance criteria context |
| §5 Requirements | REQ-# numbered requirements with P0/P1/P2 priority and acceptance criteria | Traceability: REQ-# → FR-# |
| §6 Non-Goals | Explicit exclusions with rationale | Scope boundaries |
| §7 Technical Considerations | Dependencies, constraints, known risks | Technical context |
| §8 Launch Phases | 3-tier table (Internal Alpha → Beta → GA) with success gates | Launch planning context |
| §9 Open Questions | Unresolved decisions | Risk awareness |

## Downstream Consumer Matrix

| Consumer | Reads | How | Writes |
|----------|-------|-----|--------|
| spec-architect | PRD.md | Optional context for questioning | Never |
| design-architect | PRD.md | Optional product context for design | Never |

(The ROADMAP is consumed by orchestrator, spec-architect, design-architect, resume, and progress, but it is `progress-tracker`'s output, not product-architect's — see `progress-tracker.contract.md`.)

## Guarantees

- All requirements in PRD §5 use REQ-# numbering (REQ-1, REQ-2, etc.) with P0/P1/P2 priority
- Every REQ-# has acceptance criteria
- The feature backlog handed to `progress-tracker` maps to REQ-# items via the feature decomposition
- VISION.md follows Geoffrey Moore's elevator pitch format
- All files are confirmed by the user before writing, and the ROADMAP hand-off is confirmed before `progress-tracker` is dispatched
