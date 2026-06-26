# Design Architect - User Guide

## What It Does

The Design Architect guides you through interactive architectural design decisions for a feature, producing a Software Design Document (SDD). It bridges the gap between requirements (SRS/BDD from spec-architect) and implementation planning (plan-architect).

**Model:** Claude Opus (`claude-opus-4-6`)

**Input:** `/design-architect [feature-name]` — requires SRS and BDD files to already exist in `.project/cycles/*-[feature-name]/specs/`. Run `/spec-architect` first if they don't.

**Output:** `SDD.md` (Software Design Document) written to `.project/cycles/DD-MM-YYYY-[feature]/specs/SDD.md`.

**Key Points:**
- **Interactive design** — Presents 2-3 options with recommendations for each decision
- **Codebase-grounded** — All options reference actual patterns found in your codebase
- **Lightweight output** — Captures decisions and interfaces, not enterprise architecture docs
- **Traceable** — Every decision maps to SRS requirements with line numbers
- **User-driven** — You make the decisions; the architect provides informed options

---

## When to Use It

Invoke the Design Architect after spec-architect has created SRS and BDD files, before running plan-architect.

**Pipeline position:**
```
/spec-architect → SRS + BDD
       ↓
/design-architect → SDD        ← you are here
       ↓
plan-architect → implementation plan
       ↓
plan-auditor → validation
```

| Scenario | Command |
|----------|---------|
| Design architecture for a feature | `/design-architect notification-system` |
| After updating specs | `/design-architect billing` |

**Prerequisites:**
- SRS and BDD files must exist in `.project/cycles/DD-MM-YYYY-[feature-name]/specs/`
- If they don't exist, run `/spec-architect [feature-name]` first

---

## The 6-Phase Process

### Phase 1: Feature Selection

When invoked **with** a `[feature-name]` argument, this phase is a passthrough — the Design Architect goes straight to loading the specs. When invoked **without** arguments, it runs ROADMAP-driven discovery: reads `.project/product/ROADMAP.md` to enumerate candidate features, checks the filesystem to sort them into Ready-for-SDD (SRS + BDD present, no SDD), Has-SDD, and Blocked (specs missing), and asks you to pick one. The filesystem is the source of truth — the ROADMAP is read only to list candidates, never written or reconciled.

### Phase 2: Load & Analyze (Automatic)

When invoked, the Design Architect:

1. **Resolves feature directory** — Finds `.project/cycles/*-[feature-name]/`
2. **Loads specifications** — Reads SRS.md, CONTEXT.md, and all .feature files
3. **Extracts key information** — Objective, functional requirements (with IDs and line numbers), NFRs, constraints
4. **Initializes coverage tracker** — Determines which design areas apply to this feature

### Phase 3: Deep Codebase Exploration (Automatic)

Uses the built-in Explore subagent to find:
- Existing patterns that constrain design choices
- Reusable utilities
- Similar modules to follow as templates
- Integration points with existing services
- Data model patterns

Presents findings before moving to decisions.

### Phase 4: Interactive Design Decisions (Interactive)

For each applicable design area, presents options and captures your choices:

1. **Component Architecture** — What modules/services are needed
2. **Layer Assignment** — Where each component lives per project architecture
3. **Data Model Design** — Schema structure and relations
4. **Processing Model** — Sync vs async, queues, events
5. **Interface Contracts** — How components communicate
6. **Integration Approach** — How new code connects to existing
7. **Error Handling Strategy** — Failure modes and recovery
8. **Security Approach** — Auth, RBAC, data isolation
9. **State Management** — Client-side state (frontend only)

### Phase 5: Design Verification (Interactive)

Presents a complete design summary and verifies:
- All SRS functional requirements covered
- Design aligns with codebase conventions
- No gaps or inconsistencies

Waits for your confirmation before generating.

### Phase 6: SDD Generation (Automatic)

Generates the SDD file and presents a completion summary with next steps.

---

## Understanding Design Decisions

Each decision is presented in this format:

```markdown
### Decision: [Topic]
**Context:** [What requirement drives this + codebase findings]
**Relevant Requirements:** FR-X (SRS.md:L##)

**Options:**
1. **(Recommended) [Name]** — [Description]. Pros: [...]. Cons: [...].
2. **[Name]** — [Description]. Pros: [...]. Cons: [...].

**Recommendation rationale:** [Why, with codebase evidence]
```

**What to look for:**
- The **recommended** option is always marked — it's the architect's best suggestion
- **Pros/Cons** are specific, not vague — they reference actual codebase patterns
- **Rationale** includes file:line references to existing code
- You can always choose a non-recommended option or propose modifications

---

## Understanding the SDD Output

The generated SDD contains:

| Section | What It Captures |
|---------|-----------------|
| **Meta** | Feature name, source spec, date, confidence level |
| **Design Overview** | 1-2 paragraph summary of architectural approach |
| **Component Architecture** | Table of components with layers and requirement mapping |
| **Design Decisions** | DD-1, DD-2... with context, decision, rationale, alternatives |
| **Interface Contracts** | How components communicate (methods, DTOs, errors) |
| **Data Flow** | How data moves through the system |
| **Data Model** | Schema entities and relations for this feature |
| **Integration Points** | How new code connects to existing codebase |
| **Constraints & Boundaries** | What's in/out of scope |
| **Requirement Traceability** | Maps every FR to a component and design decision |

---

## Design Areas Covered

| Area | Description | Applies When |
|------|-------------|-------------|
| Component Architecture | Modules/services and responsibilities | Always |
| Layer Assignment | Architecture layer per component | Backend features |
| Data Model Design | Schema structure and relations | SRS mentions entities/persistence |
| Processing Model | Sync/async, queues, events | Async operations or background jobs |
| Interface Contracts | Component communication signatures | Multiple new components |
| Integration Approach | Connection to existing codebase | Feature integrates with existing code |
| Error Handling Strategy | Failure modes and recovery patterns | Non-trivial failure scenarios |
| Security Approach | Auth, RBAC, data isolation | Handles user data or sensitive ops |
| State Management | Client-side state patterns | Frontend features only |

---

## Coverage Tracker

Every response during Phase 4 includes the Design Coverage Tracker:

```
## Design Coverage Tracker
- [x] Component Architecture
- [x] Layer Assignment
- [~] Data Model Design ← IN PROGRESS
- [ ] Processing Model
- [ ] Interface Contracts
- [ ] Integration Approach
- [ ] Error Handling Strategy
- [x] Security Approach
- N/A State Management
```

| Status | Meaning |
|--------|---------|
| `[ ]` | Not addressed yet |
| `[~]` | Partially addressed (some decisions made, more needed) |
| `[x]` | Complete (all decisions made for this area) |
| `N/A` | Not applicable to this feature |

---

## Tips for Best Results

### Engage with Options
Don't just accept recommendations blindly. If you have domain knowledge that changes the calculus, share it. The architect can adjust.

### Provide Context
When the architect asks about a design area, share any constraints or preferences you have. For example:
> "We plan to add real-time notifications later, so the processing model should support events."

### Think About Integration
The architect grounds decisions in existing code. If you know about upcoming changes or planned features that affect integration, mention them.

### Trust the Coverage Tracker
If an area stays `[ ]` too long, the architect will address it. All applicable areas must reach `[x]` before SDD generation.

---

## Common Scenarios

### Typical Session

```
You: /design-architect notification-system

Architect: [Loads specs, explores codebase, presents findings]

Architect: Let's start with Component Architecture.
  Decision: Service Structure
  Options:
  1. (Recommended) Single NotificationService — handles all notification operations...
  2. Split DeliveryService + PreferenceService — separates concerns...

You: [Selects option 1]

Architect: [Captures DD-1, updates tracker, moves to Layer Assignment]
  Decision: NotificationService Layer Placement
  Options:
  1. (Recommended) Domain layer — standard business logic placement...
  2. Orchestration layer — if coordinating multiple services...

You: [Selects option 1]

Architect: [Continues through applicable areas...]

Architect: [Presents design summary, verifies coverage]

You: [Confirms]

Architect: [Generates SDD.md]
```

---

## What It Won't Do

| Limitation | Reason |
|------------|--------|
| Make decisions for you | Design decisions require user judgment |
| Write code | SDDs capture decisions, not implementation |
| Skip codebase exploration | Every option must be grounded in evidence |
| Work without specs | SRS and BDD must exist first |
| Generate implementation plans | That's the plan-architect's job |

---

## Related Documentation

- **Skill definition:** `.claude/skills/design-architect/SKILL.md`
- **Interface contract:** `.claude/agents/interface-contracts/design-architect.contract.md`
- **SDD template:** `.claude/skills/design-architect/reference/sdd-template.md`
- **Spec Architect guide:** [spec-architect.guide.md](spec-architect.guide.md) — creates the specs this skill consumes
- **Plan Architect guide:** [plan-architect.guide.md](plan-architect.guide.md) — consumes the SDD this skill produces
