# Base Rules

Apply to every dispatch regardless of `Target`. Target-specific files (`feature-final-rules.md`, `test-plan-rules.md`, `refactor-plan-rules.md`) extend these with additional checks.

## Verb-noun discipline

Every task header uses a verb-noun form. The verb satisfies ONE of:

- (a) Appears in the closed allowed-verbs list at `.claude/agents/plan-architect/essentials/allowed-verbs.md`, OR
- (b) Is accompanied by an extension-request file at `.claude/docs/vocabulary-extensions/<YYYY-MM-DD>-<verb>.md` whose path the plan references.

The reference to `plan-architect/essentials/allowed-verbs.md` is an intentional cross-agent dependency. `plan-architect` is the sole writer of that list; `plan-auditor` and `agent-architect` (`process-vocabulary` mode) are the readers. The shared file lives in `plan-architect`'s tree because plan-architect is responsible for emitting verbs that satisfy it.

File existence is sufficient for condition (b). Plan-auditor does NOT evaluate the request's viability — `agent-architect` (`process-vocabulary` mode) adjudicates that separately.

Allowed noun forms: `<domain entity>` | `<type>` | `<invariant>` (see Domain-noun discipline below).

**Violation:** `UNDOCUMENTED_VERB: <verb>` (Phase N, Task N.M) — fires only when neither (a) nor (b) holds.

**Severity:** ERROR. **Confidence:** HIGH.

## One-concern discipline

Every task carries exactly one `Concern` field. Closed enum (nine values):

`validation`, `persistence`, `transformation`, `rendering`, `side-effect`, `authorization`, `infrastructure`, `test`, `convention-doc`.

Additional checks:

- `Concern` field present on every task.
- `Concern` value is one of the nine allowed.
- Task description does not contain " and " indicating multiple concerns (e.g., "validate email and persist user" should split).

**Violations:**

- `MISSING_CONCERN: Phase N, Task N.M` — field absent. **Severity:** ERROR. **Confidence:** HIGH.
- `INVALID_CONCERN: Phase N, Task N.M: <value>` — value not in the closed set. **Severity:** ERROR. **Confidence:** HIGH.
- `MULTIPLE_CONCERNS: Phase N, Task N.M` — " and " in description suggests two concerns. **Severity:** WARNING. **Confidence:** MEDIUM (heuristic — verify manually; not every " and " indicates a split).

## Domain-noun discipline

Tasks use named domain entities. Generic placeholders in noun position are rejected: `input`, `data`, `payload`, `value`, `thing`, `item`, `object`, `result`.

Examples:

- VALID: "validate email", "guard tenant scope", "format Hebrew date", "persist organization", "render Tabu block".
- REJECTED: "validate input", "process data", "transform payload", "store value".

**Violation:** `GENERIC_NOUN: Phase N, Task N.M: <generic-term>` — **Severity:** WARNING. **Confidence:** MEDIUM (heuristic; some uses of "input" or "value" are legitimate in domain terms — verify manually).

## Per-task metadata

Every task carries these three fields directly under the task header:

| Field | Format | Required |
|-------|--------|----------|
| `Target file(s)` | Backtick-wrapped path(s); use `new: <path>` for files to be created | Yes |
| `Acceptance` | Single-sentence testable predicate | Yes |
| `Concern` | One of the nine allowed values | Yes |
| `Effort` | One of `S`, `M`, `L` | Yes |

**Violation:** `MISSING_TASK_METADATA: Phase N, Task N.M: <comma-separated missing fields>` — **Severity:** ERROR. **Confidence:** HIGH.

## Phase sizing

Phase size is measured in **effort points**, not raw task count: `S` = 1, `M` = 2, `L` = 3, summed per phase. A phase ships as one developer instance on a fixed turn budget, so a phase of dense tasks must split even when its task count is low.

### Hard caps (ERROR)

- Effort points per phase ≤ 8 (sum of `S`=1, `M`=2, `L`=3 across the phase's tasks). Violation: `PHASE_OVER_BUDGET: Phase N: <points>`.
- Tasks per phase ≤ 6. Violation: `PHASE_TOO_MANY_TASKS: Phase N: <count>`.
- Files per phase ≤ 15 (touched + new combined). Violation: `PHASE_TOO_MANY_FILES: Phase N: <count>`.

### Effort-tier consistency (ERROR)

A task's declared `Effort` must be at least the tier implied by the two objectively countable axes — under-labeling to fit the budget is rejected:

- Files touched ≥3, or >6 distinct asserted behaviors in `Acceptance` → tier must be `L`.
- Files touched = 2, or 3–6 asserted behaviors → tier must be `M` or `L`.

The logic axis (algorithm, concurrency, transaction, state machine, migration, drag-and-drop) raises the tier but is not auto-checked — flag it only when the declared tier plainly contradicts the task description. Violation: `PHASE_EFFORT_UNDERWEIGHTED: Phase N, Task N.M: declared <tier>, axes imply <tier>`. **Confidence:** HIGH for the file/assertion axes; MEDIUM when invoking the logic axis.

### Mandatory phase boundaries (ERROR)

- Developer Type changes within a single phase (`backend` ↔ `frontend` ↔ `infrastructure` ↔ `test`). Violation: `PHASE_MIXED_DEVELOPER_TYPE: Phase N`.
- Target subarea changes within the same Developer Type (e.g., `src/billing` and `src/auth` in one phase). Violation: `PHASE_MIXED_SUBAREA: Phase N`. **Confidence:** MEDIUM (heuristic — subarea boundaries are inferred from path prefixes; verify manually).
- Task depends on a prior task being committed but lives in the same phase. Violation: `PHASE_INTRA_COMMIT_DEPENDENCY: Phase N, Task N.M`.

### Soft targets (WARNING)

- Effort points per phase target 4–6 when tasks span >1 file or >1 entity. Violation: `PHASE_SOFT_TARGET_EFFORT: Phase N: <points>`.

Soft-target findings are MEDIUM confidence (heuristic — verify manually).

## Code-reference grounding

Every code reference in the plan resolves at HEAD via Glob. References include: `Target file(s)` paths, REUSE directive cited paths, EXTRACT directive cited paths (for the consuming task target), ABSTRACT annotation source-file paths, BDD scenario feature-file paths.

### Protocol

1. For each path, run `Glob` against the path.
2. Paths declared as `new: <path>` or describing a file to be created are exempt — the file is expected NOT to exist yet.
3. `Target file(s)` paths in tasks whose Action plainly creates a new file are exempt (apply judgment from task content).

### Violations

- `PATH_NOT_FOUND: <path>` (Phase N, Task N.M, or table section name)
  - **Severity:** ERROR for `Reference` fields and approved-finding cited paths (must already exist).
  - **Severity:** WARNING for `Target file(s)` paths where new-file intent is ambiguous.
- `PATH_NEW_BUT_EXISTS: <path>` — path is declared `new:` but already exists at HEAD. **Severity:** WARNING.

**Confidence:** HIGH (Glob result is deterministic).

## Charter grounding

A backstop check for off-charter third-party dependencies that reach a plan. The primary gate is `design-auditor`, which enforces the Tech Stack Charter at the SDD before plan-architect decomposes it into tasks. This check catches dependencies that surface only in plan tasks — a REUSE/EXTRACT directive importing a new library, or an Action that adds or installs one.

### What to scan

Inspect each task for an indication of a new third-party dependency:

- An import of a package not already present in the repo's `package.json`.
- An `Action` that adds or installs a dependency.
- An `Integration` referencing an external service.

### Protocol

1. Glob `.project/knowledge/tech-stack/charter.md`, read from the **main root** — the charter is main-canonical; on any merge conflict on `.project/knowledge/tech-stack/**`, take main.
2. If the charter exists, Grep it for the technology identifier. A technology present as an `Approved` row is fine.
3. If the technology is absent or not `Approved` → `OFF_CHARTER_DEPENDENCY`. If the charter file is absent → `CHARTER_MISSING` (once, plan-level).

### Violations

- `OFF_CHARTER_DEPENDENCY: <identifier>` (Phase N, Task N.M) — task introduces a third-party dependency not Approved in the charter. **Severity:** ERROR. **Confidence:** MEDIUM (heuristic — some imports resolve to internal modules, not third-party packages; verify before trusting).
- `CHARTER_MISSING` (plan-level) — no `.project/knowledge/tech-stack/charter.md` exists; the project has not adopted a charter. **Severity:** WARNING. **Confidence:** HIGH.

## Simplicity grounding

An advisory check for over-engineering that reaches the plan — structure the plan asks for that no present requirement pulls in. All findings here are advisory (WARNING) and heuristic: surface them with the simpler alternative; do not block a plan on a simplicity judgment call. The test for every signal: does an SRS/SDD requirement or an approved finding *force* this structure, or was it added in anticipation?

### What to scan

Inspect tasks and phases for structure that lacks a traceable, present justification:

- A task creating a **shared utility, helper, or abstraction** (`new:` file in a shared/util directory, or a task whose noun is a generic handler/base/wrapper) whose consumers number **fewer than three** — count call sites named across the plan and verifiable at HEAD via Grep.
- A new file, service, queue, cache, or datastore introduced by a task that **does not trace to an SDD design decision** — an addition the design did not call for.
- A phase, task, parameter, or config option whose only rationale is a future or hypothetical need — language like "to support future…", "extensible for…", "in case…" with no SRS requirement behind it.

### Protocol

1. For each candidate, check whether an SRS/SDD requirement or an approved REUSE/EXTRACT/ABSTRACT finding justifies it. An approved ABSTRACT directive carries its own upstream approval — never flag it as over-engineering.
2. For shared-code candidates, Grep the codebase for existing consumers to count call sites before flagging.
3. Flag only when no present justification is found; when uncertain, prefer no finding over a false positive.

### Violations

- `SPECULATIVE_STRUCTURE: Phase N, Task N.M: <what>` — structure with no present requirement behind it (single-consumer shared helper, unflagged new infrastructure, future-need-only config). **Severity:** WARNING. **Confidence:** MEDIUM (heuristic — judgment call; verify before trusting, and defer to an approved finding if one exists).

## Plan-header discipline (Objective)

Every plan — every `Target`, no exception — opens with a non-empty `## Objective` section (1–2 sentences naming the plan's goal), positioned above the first `## Phase` heading when phases are present, else near the top of the plan.

This rule is **full-audit only**: the `## Objective` sits above any single phase's scope, so `phase-audit` cannot evaluate it and skips it.

**Violation:** `MISSING_OBJECTIVE` — the `## Objective` section is absent or empty. **Severity:** ERROR. **Confidence:** HIGH. **Location:** plan-level.
