# Writing Discipline

Every plan emitted by `plan-architect` honors the rules below. Plan-auditor enforces them; failing any rule blocks downstream pipeline progress.

## A. Verb-noun task headers from closed vocabulary

Task headers use the form `<verb> <noun>` where `<verb>` comes from `allowed-verbs.md` and `<noun>` is a named domain entity, type, or invariant. Unlisted verbs are admissible only when paired with an extension-request file (see `vocabulary-extension.md`).

The verb names **what the resulting code does at runtime**, not the editing gesture that produces it. When naming a task, ask "what does the resulting code *do*?" and pick that verb — a task that changes existing code takes the same behavior verb it would if the code were new. Whether a task creates or edits an existing file is carried solely by the `new:` prefix on `Target file(s)` (Rule D), so the verb never encodes it.

## B. One concern per task

A task addresses exactly one of nine concerns, declared in its `Concern` field:

- `validation`
- `persistence`
- `transformation`
- `rendering`
- `side-effect`
- `authorization`
- `infrastructure`
- `test`
- `convention-doc`

If a task description joins two responsibilities with "and", split it. `convention-doc` marks tasks that write or update convention files under `.project/knowledge/<type>/**/*.md`; the orchestrator routes these tasks to `state-manager` (`refactor-curation` mode) rather than `developer`.

## C. Domain-noun discipline

Tasks reference named domain entities. Generic terms — `input`, `data`, `payload`, `value`, `result`, `thing`, `item` — are rejected in noun position. Prefer the named entity (`Tabu PDF block`, `organization`, `Hebrew date`) the SRS, SDD, or codebase already uses.

## D. Per-task metadata block (mandatory)

Every task carries this metadata block beneath its verb-noun header:

```
- Target file(s): <explicit path> | new: <path>
- Acceptance: <testable predicate, one sentence>
- Concern: <one of the nine categories above>
- Effort: S | M | L
```

Field rules:

- **`Target file(s)`** — exact paths. `new: <path>` for files the task creates. Lists are permitted when a single concern touches multiple files for the same change (e.g., a Prisma migration plus its companion seed).
- **`Acceptance`** — one sentence with a verifiable predicate. Either an executable check (`npm run test -- -t "validates Tabu block"`) or a structured `[manual]` step list with a reason (`[manual] Step 1: open /admin. Step 2: confirm RTL layout. (Reason: visual)`).
- **`Concern`** — exactly one of the nine values above. Plan-auditor rejects any other string.
- **`Effort`** — `S`, `M`, or `L`, assigned per the tier rubric in `phase-sizing.md`. Governs the phase's effort budget; under-labeling is rejected by the auditor's consistency check.

Rules A–D apply to every target (`feature-draft`, `feature-final`, `test-plan`, `refactor-plan`, `bugfix-reproduction`, `bugfix-draft`, `bugfix-final`).

## E. Plan header (mandatory)

Every plan's header begins with a `## Objective` section; test plans carry an additional `## Meta` section below it:

- **`## Objective` (every plan)** — 1–2 sentences naming the plan's ultimate goal: the feature's or refactor's end state, the bug the fix restores, or the behaviors a phase's tests verify. The orchestrator passes it to every developer and code-reviewer invocation, so it must read as standalone context for an instance that sees only one phase.
- **`## Meta` (test plans only)** — one line: `BDD Specs: <path to the feature's specs/bdd/ directory>`, positioned below the `## Objective`.

Plans carry **no `## Quick Reference` section**, and only test plans carry a `## Meta` section. Reuse is expressed per task (`Reference`, REUSE/EXTRACT directives); orientation comes from `.project/knowledge/`; cross-phase context comes from the handoff.

### Open Questions

Include `## Open Questions` on any plan **only when planning surfaced unresolved questions** the user should resolve — omit the section entirely when there are none. Each item is a checkbox line (`- [ ] ...`). When present, it follows the header sections (after `## Objective`, and after `## Meta` on a test plan).
