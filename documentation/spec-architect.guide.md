# Spec Architect - User Guide

## What It Does

The Spec Architect (internally called "The Specification Architect") transforms vague feature ideas into precise, implementable specifications through structured questioning and codebase exploration.

**Model:** Claude Opus

**Input:** `/spec-architect [feature-name]` — a feature name. The Spec Architect infers which layers the feature touches; you never declare a type.

**Output:** SRS.md + BDD files (CONTEXT.md, `*.feature` files) written to `.project/cycles/DD-MM-YYYY-[feature-name]/specs/`.

**Key Points:**
- **Progressive questioning** - Asks questions in logical groups, building on previous answers
- **Codebase-aware** - Explores existing patterns before asking questions
- **No assumptions** - Every ambiguity triggers a follow-up question
- **Coverage tracking** - Shows progress across all requirement areas
- **Generates artifacts** - Produces SRS and BDD specifications ready for implementation

---

## When to Use It

Invoke the Spec Architect when you need to:

| Scenario | Command |
|----------|---------|
| Spec a named feature | `/spec-architect payment-system` |
| Pick a feature from the ROADMAP | `/spec-architect` (lists candidates) |

**Best Use Cases:**
- Before implementing a new feature
- When requirements are unclear or evolving
- When you need to document decisions for team alignment
- When you want executable BDD scenarios for test-driven development

---

## The 5-Phase Process

### Phase 1: Feature Selection

When invoked **with** a `[feature-name]` argument, this phase is a passthrough — the Spec Architect goes straight to initialization. When invoked **without** arguments, it runs ROADMAP-driven discovery: reads `.project/product/ROADMAP.md` to enumerate candidate features, checks the filesystem to see which already have specs, and asks you to pick one. The filesystem is the source of truth — the ROADMAP is read only to list candidates, never written or reconciled.

### Phase 2: Initialization & Exploration (Automatic)

When invoked, the Spec Architect:

1. **Parses arguments** - Determines the feature name; type is not declared — the skill infers which layers the feature touches from exploration + description
2. **Loads discovery framework** - Draws question templates per topic cluster, just-in-time
3. **Explores codebase** - Uses the built-in Explore subagent to find relevant patterns
4. **Presents summary** - Shows found patterns, integration points, conventions

**Example output:**
```
## Codebase Exploration Summary

I've analyzed the codebase to tailor questions to your existing patterns.

### Found Patterns
- PaymentService in src/services/payments/
- AuthGuard decorator for protected endpoints
- Existing payment DTOs and validation

### Potential Integration Points
- BillingService for invoice processing
- UserService for account management

### Existing Conventions
- Result pattern for service returns
- Validation utilities for user-facing content
```

### Phase 3: Dynamic Requirements Discovery (Interactive)

This is the core phase. The Spec Architect asks questions in logical groups, tracks coverage, and never makes assumptions.

**Question flow:**
```
Core Identity → Context & Scope → Technical Details → Cross-Cutting Concerns
```

**What you'll see after each response:**

1. **Interpreted Requirements** - Your vague answers rewritten with technical precision
2. **Clarification Needed** - Any ambiguities that need resolution
3. **Coverage Tracker** - Progress across all requirement areas

### Phase 4: Specification Generation

Once all areas are covered (`[x]`), the Spec Architect:

1. **Verifies completeness** against standards
2. **Presents full summary** for your approval
3. **Waits for confirmation** before generating
4. **Generates SRS** (Software Requirements Specification)
5. **Generates BDD files** (Gherkin scenarios)

### Phase 5: Handoff

Delivers final artifacts with implementation suggestions and next steps.

---

## Understanding the Coverage Tracker

Every response during Phase 3 includes the Coverage Tracker:

```
## Coverage Tracker
- [x] Core Identity
- [x] Context & Scope
- [~] API Design ← IN PROGRESS (endpoints defined, validation rules needed)
- [ ] Data Model
- [ ] Business Logic
- [ ] Error Handling
- [ ] Security
- [ ] Integration
- [ ] Performance
- [ ] Testing
```

### Status Meanings

| Status | Meaning |
|--------|---------|
| `[ ]` | Not started - no information gathered yet |
| `[~]` | Partially covered - some info, but gaps remain |
| `[x]` | Complete - all required information gathered |

### Topics by Active Layer

The Spec Architect infers which layers the feature touches (you don't declare a type) and tracks topics for those layers only. Topics for untouched layers are marked `N/A` and excluded.

| Active Layer | Topics |
|----------|--------|
| **Always** | Core Identity, Context & Scope |
| **Backend** | API Design, Data Model, Business Logic, Error Handling, Security, Integration, Performance, Backend Testing |
| **Frontend** | Routing, UI Components, State & Data, Forms, Accessibility, Styling & Icons, Frontend Performance, Frontend Testing |
| **Backend + Frontend (coordination)** | API Contract Alignment, Error Mapping, Auth Flow, State Sync, E2E Testing, Deployment Coordination |
| **Infrastructure** (only when the feature changes infra) | Current vs Target State, Migration Strategy, Deployment, Monitoring, Infra Security, Backup & Recovery, Scaling, Infra Testing, Communication |

**Note:** Conditional cross-cutting blocks (i18n, multi-tenancy) are added per project requirements (CLAUDE.md / PRD).

---

## Understanding the Output

### During Discovery (Phase 3)

```markdown
## Interpreted Requirements

- **Action:** File upload endpoint (POST /api/files)
- **Actor:** Authenticated users with 'uploader' role
- **Processing:** Asynchronous job (queue-based)

## Clarification Needed

Your response mentions "process them" — this is ambiguous:
- What type of processing? (parsing, validation, transformation?)
- Where does processing happen? (synchronous, background job?)

## Coverage Tracker
[Updated status of all topics]

## Next Questions

[2-3 questions for the next logical topic]
```

### Final Artifacts (Phase 4)

| File | Location | Purpose |
|------|----------|---------|
| **SRS.md** | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/SRS.md` | Complete requirements specification |
| **CONTEXT.md** | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/CONTEXT.md` | BDD background and domain language |
| **[feature].feature** | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/` | Main Gherkin scenarios |
| **[feature]-errors.feature** | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/` | Error handling scenarios |
| **[feature]-edge-cases.feature** | `.project/cycles/DD-MM-YYYY-[feature-name]/specs/bdd/` | Edge case scenarios |

---

## Tips for Best Results

### Be Specific

| Less Effective | More Effective |
|----------------|----------------|
| "Users upload files" | "Authenticated users upload CSV files up to 10MB for batch processing" |
| "Show a list" | "Display paginated list of orders with search by name and date filters" |
| "Handle errors" | "Show localized error messages with retry option for network failures" |

### Answer Completely

The more detail you provide, the fewer follow-up questions you'll get. When asked about error handling, think through:
- What errors can occur?
- How should each be displayed?
- What recovery options exist?

### Don't Fight the Process

If the Spec Architect asks about something you think is irrelevant, explain why. It tracks coverage because features need comprehensive specs. You might say:
> "This feature doesn't handle user input, so input validation isn't needed"

### Use the Coverage Tracker

Glance at the tracker after each response. If a topic stays `[~]` for too long, proactively provide the missing information.

---

## Common Scenarios

### Starting a Feature

```
You: /spec-architect payment-processing

Spec Architect: [Explores codebase, finds PaymentService, infers active layers, presents summary]

Spec Architect: Let's start with Core Identity...
1. What triggers payment processing?
2. What payment methods are supported?
3. What happens when payment fails?

You: Triggered when user confirms checkout. Credit card and bank transfer. Show error and allow retry.

Spec Architect: [Rewrites with precision, flags "show error" as vague, asks for details]
```

### A Feature Touching Both Layers

```
You: /spec-architect document-sharing

Spec Architect: [Explores backend and frontend patterns; infers active-layers: [backend, frontend]]

Spec Architect: This feature crosses the API boundary, so I'll cover both layers
plus the coordination seams. Starting with Core Identity...
```

### Resuming After Interruption

The Spec Architect maintains state through the Coverage Tracker. If you need to resume:
```
You: Let's continue with the document-sharing spec

Spec Architect: [Shows current Coverage Tracker, picks up where you left off]
```

---

## What It Won't Do

| Limitation | Reason |
|------------|--------|
| Make implementation decisions | Specs describe WHAT, not HOW |
| Skip coverage areas | Comprehensive specs prevent implementation gaps |
| Assume "obvious" requirements | What's obvious varies; everything gets documented |
| Generate code | Specs are for planning; implementation is separate |

---

## Output Quality Guarantees

| Guarantee | What It Means |
|-----------|---------------|
| **No assumptions** | Every requirement traces to your explicit answer |
| **Technical precision** | Vague language rewritten as specific requirements |
| **Codebase integration** | Specs reference actual files and patterns |
| **Testable requirements** | BDD scenarios executable as tests |
| **Complete coverage** | All relevant topics addressed |

---

## Related Files

The Spec Architect's configuration and reference materials:

```
.claude/skills/spec-architect/
├── SKILL.md                        # Main skill definition
└── reference/
    ├── srs-template.md             # SRS document template
    ├── bdd-template.md             # BDD file templates
    ├── backend/
    │   ├── discovery-prompts.md    # Backend question templates
    │   └── standards.md            # Backend requirements standards
    ├── frontend/
    │   ├── discovery-prompts.md    # Frontend question templates
    │   └── standards.md            # Frontend requirements standards
    ├── fullstack/
    │   └── ...                     # Cross-layer coordination prompts/standards
    └── infrastructure/
        └── ...                     # Infrastructure prompts/standards
```

---

## Related Documentation

- **Design Architect**: [design-architect.guide.md](design-architect.guide.md) - Next step after spec-architect; creates SDD from specs
- **Agent Architect**: [agent-architect.guide.md](agent-architect.guide.md) - Create new agents/skills
- **Agent Auditor**: [agent-auditor.guide.md](agent-auditor.guide.md) - Validate agent designs
