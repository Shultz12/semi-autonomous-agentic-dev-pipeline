# Product Architect - User Guide

## What It Does

The Product Architect transforms a product idea into structured documents that anchor all downstream development work — from feature specs through implementation. It writes VISION.md and PRD.md itself, and hands the roadmap off to `progress-tracker`, which owns `ROADMAP.md`.

**Model:** Claude Opus (`claude-opus-4-6`)

**Input:** `/product-architect [create|update]` — mode argument. If omitted, auto-detects based on whether product documents already exist.

**Output:** VISION.md and PRD.md in `.project/product/`, plus a `progress-tracker` `init` dispatch that creates `.project/product/ROADMAP.md`.

**Key Points:**
- **Progressive questioning** — Asks questions in logical groups, building on previous answers
- **Incremental persistence** — Writes each file as soon as its area is fully covered
- **No assumptions** — Every ambiguity triggers a follow-up question
- **Coverage tracking** — Shows progress across 10 product definition areas
- **Two modes** — Create from scratch or update existing documents

---

## When to Use It

| Scenario | Command |
|----------|---------|
| Starting a brand new product | `/product-architect create` |
| Starting a product (auto-detect) | `/product-architect` |
| Updating vision or requirements | `/product-architect update` |
| Adding milestones to roadmap | `/product-architect update` |
| Refining after direction change | `/product-architect update` |

**Use this skill when:**
- You have a product idea and need to formalize it before building
- Product direction has changed and documents need updating
- You need a roadmap to plan feature work

**Do NOT use for:**
- Individual feature requirements → use `/spec-architect`
- Architectural design decisions → use `/design-architect`
- Implementation planning → use plan-architect

---

## The Process

### Create Mode

The Product Architect guides you through 5 questioning stages:

```
Stage 1: Vision       → What's the product? What problem? Who has it?
Stage 2: Users        → Who uses it? What value? How different? → Writes VISION.md
Stage 3: Requirements → What capabilities? What priority? What's excluded?
Stage 3b: Features    → How do requirements group into buildable units?
Stage 4: Launch       → How measure success? How roll out? → Writes PRD.md
Stage 5: Roadmap      → What milestones? What order? → Dispatches progress-tracker to create ROADMAP.md
```

Each file is written incrementally — if the conversation is interrupted, everything gathered so far is preserved.

### Update Mode

1. Reads your existing documents and presents a summary
2. Asks what you want to change
3. Re-questions only the affected areas
4. Shows what changed before writing updates

---

## Understanding the Coverage Tracker

Every response during questioning includes the Product Definition Tracker:

```
## Product Definition Tracker
- [x] Vision — product identity, problem, users, value prop, differentiation
- [x] Users — target user types with needs
- [~] Requirements ← IN PROGRESS (3 capabilities defined, priorities needed)
- [ ] Feature Decomposition — requirements grouped into named features
- [ ] Non-Goals
- [ ] Success Metrics
- [ ] Technical Constraints
- [ ] Launch Plan
- [ ] Roadmap
```

### Status Meanings

| Status | Meaning |
|--------|---------|
| `[ ]` | Not started — no information gathered yet |
| `[~]` | Partially covered — some info, gaps remain |
| `[x]` | Complete — all required information gathered |

---

## Understanding the Output

### VISION.md

A 1-page product identity document. Opens with Geoffrey Moore's elevator pitch format:

> For [target users] who [need], [Product] is a [category] that [benefit]. Unlike [alternative], our product [differentiation].

### PRD.md

Product requirements with REQ-# numbering (REQ-1, REQ-2, etc.) and P0/P1/P2 priorities. Each requirement has acceptance criteria. Includes problem statement with evidence, target users, success metrics, launch phases, non-goals, and open questions.

### ROADMAP.md

Milestone-based roadmap authored by `progress-tracker` from the milestones, success criteria, and feature decomposition the Product Architect hands off. Each milestone lists its not-yet-started features in a backlog; a feature becomes a dated `### <slug>` entry when work on it begins. Features map back to REQ-# items. Includes a "What We're Not Building" section with rationale and revisit conditions. `progress-tracker` owns the file and every status transition on it.

---

## Tips for Best Results

### Think Big, Then Narrow

Start with the broadest vision of what you want to build. The Product Architect will progressively narrow down to specifics. Don't jump to implementation details in early stages.

### Be Honest About Unknowns

When asked about metrics or technical constraints, it's fine to say "I don't know yet." The Product Architect captures unknowns in the PRD's Open Questions section rather than forcing premature decisions.

### Group Your Requirements by User Value

When asked about capabilities, think from the user's perspective: "What can users DO with this product?" rather than "What modules do we need?" The Feature Decomposition stage will handle the technical grouping.

### Review Before Confirming

The Product Architect shows you each file before writing it. Take time to review — changes after writing are possible but more disruptive than catching issues in review.

---

## Common Scenarios

### New Product From Scratch

```
You: /product-architect

Product Architect: I'm the Product Architect. Let's start with the big picture...
1. What product do you want to build?
2. What problem does it solve?
3. Who has this problem?

You: I want to build a tool that extracts data from Hebrew land registry PDFs
     and converts them to structured Excel files. Real estate lawyers waste hours
     doing this manually.

Product Architect: [Rewrites with precision, asks follow-up about user types,
                    document types, extraction accuracy needs...]
```

### Adding a Milestone

```
You: /product-architect update

Product Architect: I've read your existing product documents:
- VISION.md: SaaS platform for Hebrew PDF extraction
- PRD.md: 12 requirements (4 P0, 5 P1, 3 P2)
- ROADMAP.md: 2 milestones (v1.0 in-progress, v1.1 planned)

What would you like to update?

You: I want to add a v2.0 milestone for API access

Product Architect: [Asks about v2.0 features, success criteria, then dispatches progress-tracker to add the v2.0 milestone to the ROADMAP]
```

---

## What It Won't Do

| Limitation | Reason |
|------------|--------|
| Select technologies or frameworks | Product-architect defines WHAT, not HOW. Use design-architect. |
| Create feature-level specs | Product-level REQ-# requirements only. Use spec-architect for FR-# details. |
| Plan implementation | Use plan-architect after specs and design are complete. |
| Market sizing or competitive analysis | Separate specialized activities. Brief differentiation suffices. |

---

## Related Files

```
.claude/skills/product-architect/
├── SKILL.md                          # Main skill definition
└── reference/
    ├── vision-template.md            # VISION.md template
    └── prd-template.md               # PRD.md template
```

The ROADMAP is not templated here — `progress-tracker` owns its format and authors it on the `init` dispatch.

- **Interface contract**: `.claude/agents/interface-contracts/product-architect.contract.md`

---

## Related Documentation

- **Spec Architect**: [spec-architect.guide.md](spec-architect.guide.md) — Next step; creates feature-level SRS + BDD from product requirements
- **Design Architect**: [design-architect.guide.md](design-architect.guide.md) — Creates SDD from feature specs
- **Plan Architect**: [plan-architect.guide.md](plan-architect.guide.md) — Creates implementation plans from specs + design
