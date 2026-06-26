# design-architect Interface Contract

## Input

design-architect is user-invoked. It supports two invocation modes:

### With a feature name

```
Feature: [feature-name]
```

The feature name is passed as an argument to `/design-architect [feature-name]`. Phase 1 (Feature Selection) is a passthrough and the skill proceeds directly to loading the specs.

### Without a feature name

```
/design-architect
```

Phase 1 runs ROADMAP-driven discovery: it reads `.project/product/ROADMAP.md` (read-only) to enumerate candidate features, checks the filesystem to sort them into Ready-for-SDD (SRS + BDD present, no SDD), Has-SDD, and Blocked (specs missing), and asks the user to pick one. The filesystem is the source of truth; the ROADMAP is never written. Once the user picks, the flow continues exactly as the with-feature-name mode.

**Expected files (resolved via Glob `.project/cycles/*-[feature-name]/`):**
- `[feature-dir]/specs/SRS.md` — Software Requirements Specification
- `[feature-dir]/specs/bdd/CONTEXT.md` — BDD context and domain language
- `[feature-dir]/specs/bdd/*.feature` — Gherkin feature files

## Output

### Success

```
SDD created: .project/cycles/DD-MM-YYYY-[feature-name]/specs/SDD.md

Summary:
- Design decisions: [N]
- Components defined: [N]
- Design confidence: [High | Medium | Low]
- Requirements covered: [N/total]
```

### Error

```
Error: Unable to complete design

Reason: [specific reason]
- Missing files: [list with full paths]
- Recommendation: [action — e.g., run /spec-architect first]
```

## SDD Structure

The output SDD at `[feature-dir]/specs/SDD.md` follows this structure:

| Section | Purpose | For Plan-Architect |
|---------|---------|------------------|
| Meta | Feature name, source spec, date, confidence | Track SDD identity |
| Design Overview | Architectural approach summary | Understand design philosophy |
| Component Architecture | Components with layers and requirements | Map to implementation phases |
| Design Decisions (DD-#) | Each decision with context, rationale, alternatives | Use as constraints for plan tasks |
| Interface Contracts | Component interaction signatures | Define implementation interfaces |
| Data Flow | How data moves through the system | Understand processing pipeline |
| Data Model | Schema overview for this feature | Plan database migrations |
| Integration Points | How new code connects to existing | Identify dependencies |
| Constraints & Boundaries | Scope and limitations | Respect design boundaries |
| Requirement Traceability | FR → Component → DD-# mapping | Verify complete coverage |

## Example

```
/design-architect auth
```

Expects `SRS.md`, `CONTEXT.md`, and `*.feature` files in `.project/cycles/*-auth/specs/`. Produces `.project/cycles/*-auth/specs/SDD.md` after interactive design decisions with the user.

## Guarantees

- Every DD-# includes requirement references with SRS line numbers: `FR-X (SRS.md:L##)`
- Requirement Traceability table covers ALL SRS functional requirements
- All component layer assignments match project architecture layers
- Integration Points reference actual codebase files verified via codebase exploration
- All design decisions were confirmed by the user interactively
- SDD does not restate requirements from SRS — it captures decisions only
