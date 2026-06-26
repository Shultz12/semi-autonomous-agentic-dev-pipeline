# pattern-analyst Interface Contract

pattern-analyst runs in one of four modes selected by the `Mode:` field in the prompt:
`convergence-scout`, `divergence-scout`, `primitives-scout`, `curate`. All modes operate
inside the worktree where they are invoked and write only to
`.project/cycles/<slug>/refactor-proposals/`. No mode commits to main or runs any
`git -C <main-root> ...` command. Artifacts reach main exclusively via `/accept-feature`.

pattern-analyst is the sole owner of ABSTRACT decisions across the pipeline. ABSTRACT
candidates are evaluated internally and emitted as structured findings with a full
decision payload (hard-gates + scoring-axes + call-site data + phase-splitting
recommendation). The orchestrator does not evaluate ABSTRACT viability; it consumes the
structured finding. Plan-architect never re-evaluates and never re-runs
`find-call-sites.ts`.

## Slug Dispatch

Every mode (including `curate`) receives `slug: <slug>` as a dispatch input. The
orchestrator owns the slug (it created the worktree); modes never infer the slug from
filesystem state. The slug value is `<DD-MM-YYYY>-refactor-from-<parent-name>` for the
scout-and-refactor flow and `<DD-MM-YYYY>-primitives` for the primitives flow.

Missing `slug:` produces:

```
Status: ESCALATE
Reason: MISSING_SLUG
Commit: none
```

Like `UNKNOWN_MODE`, this escalation fires before any mode file is loaded and before any
artifact is written, so `Commit: none` is the only valid field value.

## Mode Validation

The `Mode:` field must match one of the four allowed values: `convergence-scout`,
`divergence-scout`, `primitives-scout`, `curate`. Any other value (typo, empty, or
unrecognized) produces:

```
Status: ESCALATE
Reason: UNKNOWN_MODE: <value>
Commit: none
```

Like `MISSING_SLUG`, this escalation fires before any mode file is loaded and before any
artifact is written, so `Commit: none` is the only valid field value.

## Input — `convergence-scout` mode

Dispatched by the orchestrator post-merge in a scout-and-refactor worktree, SECOND
(after `divergence-scout`).

**Required:**
```
Mode: convergence-scout
slug: <DD-MM-YYYY>-refactor-from-<parent-name>
```

### Example Invocation

```
Mode: convergence-scout
slug: 19-04-2026-refactor-from-pdf-extraction
```

## Input — `divergence-scout` mode

Dispatched by the orchestrator post-merge in a scout-and-refactor worktree, FIRST (owns
`inventory-utils.ts` bootstrap; `convergence-scout` consumes the bootstrapped copy
second).

**Required:**
```
Mode: divergence-scout
slug: <DD-MM-YYYY>-refactor-from-<parent-name>
```

### Example Invocation

```
Mode: divergence-scout
slug: 19-04-2026-refactor-from-pdf-extraction
```

## Input — `primitives-scout` mode

Dispatched by the orchestrator when ≥2 accepted SRSes exist in `.project/cycles/`.

**Required:**
```
Mode: primitives-scout
slug: <DD-MM-YYYY>-primitives
```

### Example Invocation

```
Mode: primitives-scout
slug: 19-04-2026-primitives
```

## Input — `curate` mode

Dispatched by the orchestrator after `pattern-analyst-auditor` has produced
`pattern-audit.md` in the cycle subdirectory.

**Required:**
```
Mode: curate
slug: <DD-MM-YYYY>-refactor-from-<parent-name> | <DD-MM-YYYY>-primitives
```

### Example Invocation

```
Mode: curate
slug: 19-04-2026-refactor-from-pdf-extraction
```

## Output

pattern-analyst writes its artifacts inside the worktree, commits them path-scoped via
the `commit-to-git` skill as the final step of each mode, and returns a structured
message. The artifacts are the source of truth for downstream consumers; the message
provides routing data for the orchestrator. Every return carries a `Commit:` field so the
orchestrator can apply interrupted-commit recovery if the field is missing.

### Output Layout (per cycle)

Scout-and-refactor flow:
```
.project/cycles/<slug>/refactor-proposals/
├── pattern-findings-convergence.md       (convergence-scout)
├── pattern-findings-convergence-original.md   (curate, if a MODIFY-AS targets this file)
├── pattern-findings-divergence.md        (divergence-scout)
├── pattern-findings-divergence-original.md
├── pattern-audit.md                      (pattern-analyst-auditor — NOT pattern-analyst)
├── pattern-audit-original.md             (curate, if MODIFY-AS resolved)
└── pattern-approved.md                   (curate)
```

Primitives flow:
```
.project/cycles/<slug>/refactor-proposals/
├── pattern-findings.md                   (primitives-scout)
├── pattern-findings-original.md          (curate, if MODIFY-AS resolved)
├── pattern-audit.md                      (pattern-analyst-auditor — NOT pattern-analyst)
├── pattern-audit-original.md
└── pattern-approved.md                   (curate)
```

### Message — `convergence-scout` success

```
Status: SUCCESS
Mode: convergence-scout
Slug: <slug>
Findings File: .project/cycles/<slug>/refactor-proposals/pattern-findings-convergence.md
Counts:
  Layer-1: <n>
  Layer-2: <n>
  Layer-3 inspections: <n>
  ABSTRACT candidates: <n>
  EXTRACT findings: <n>
Commit: <short-hash> | skipped | failed
```

### Message — `divergence-scout` success

```
Status: SUCCESS
Mode: divergence-scout
Slug: <slug>
Findings File: .project/cycles/<slug>/refactor-proposals/pattern-findings-divergence.md
Counts:
  REUSE findings: <n>
Commit: <short-hash> | skipped | failed
```

### Message — `primitives-scout` success

```
Status: SUCCESS
Mode: primitives-scout
Slug: <slug>
Findings File: .project/cycles/<slug>/refactor-proposals/pattern-findings.md
Counts:
  CREATE findings: <n>
  ABSTRACT candidates: <n>
  SRSes considered: <n>
Commit: <short-hash> | skipped | failed
```

### Message — `curate` success (approved proposals exist)

```
Status: SUCCESS
Mode: curate
Slug: <slug>
Result: APPROVED_PROPOSALS_EXIST
Approved File: .project/cycles/<slug>/refactor-proposals/pattern-approved.md
Counts:
  ACCEPT: <n>
  REJECT: <n>
  MODIFY-AS resolved: <n>
Commit: <short-hash> | skipped | failed
```

### Message — `curate` success (no approved proposals)

```
Status: SUCCESS
Mode: curate
Slug: <slug>
Result: NO_PROPOSALS_APPROVED
Approved File: .project/cycles/<slug>/refactor-proposals/pattern-approved.md
Counts:
  REJECT: <n>
  MODIFY-AS resolved: <n>
Commit: <short-hash> | skipped | failed
```

The orchestrator interprets `NO_PROPOSALS_APPROVED` to skip plan-architect dispatch and
ship the cycle as a no-op.

### Message — Failure (any mode, write did not occur)

```
Status: ESCALATE
Mode: <mode-name>
Reason: <one-line reason>
Commit: none
```

### Message — Failure (any mode, write occurred but commit raised an error)

```
Status: ESCALATE
Mode: <mode-name>
Reason: <one-line reason>
Commit: failed
```

### `Commit:` Field Semantics

| Value | Meaning |
|---|---|
| `<short-hash>` | Mode-final commit succeeded path-scoped to the worktree. |
| `skipped` | All paths in the commit set matched HEAD byte-for-byte; no empty commit was forced. |
| `failed` | Write succeeded but the commit raised an error (lock contention, hook rejection, transient). Artifacts are on disk; treat as recoverable failure. |
| `none` | No artifact was written this invocation (ESCALATE before any write). |

The orchestrator uses the presence/absence of `Commit:` as the interrupted-commit
recovery signal — a return without `Commit:` (or a missing return) triggers re-dispatch
of the same invocation.

## Finding-Directive Catalog

The findings files carry one of the following directives per finding. Each shape is
documented in the mode that emits it.

| Directive | Emitted by | Purpose |
|---|---|---|
| EXTRACT | `convergence-scout` | Consolidate a duplicated cluster into a new shared utility |
| ABSTRACT | `convergence-scout`, `primitives-scout` | Generalize an existing narrow utility (full payload per `references/abstract-migration.md`) |
| REUSE | `divergence-scout` | Replace a divergent inline implementation with an existing utility or convention |
| CREATE | `primitives-scout` | Create a new shared utility required by ≥2 accepted SRSes |
| REMOVE | any scout | Drop unused/superseded code (rare; emitted when surfaced) |
| RELOCATE | any scout | Move a utility to its correct architectural location (rare) |

## Severity / Verdict Definitions (in `pattern-audit.md`)

The verdicts used by `pattern-analyst-auditor` and consumed by `curate`:

| Verdict | Meaning | Curate action |
|---|---|---|
| `ACCEPT` | Finding is correct as written | Pass through to `approved.md` |
| `REJECT` | Finding is incorrect; drop it | Drop from `approved.md`. **Final** — curate never alters `REJECT`. |
| `MODIFY-AS:<corrected-shape>` | Finding is directionally correct but needs the corrected shape | Curate edits the finding to match the corrected shape AND changes the verdict to `ACCEPT`. Always becomes `ACCEPT`, never `REJECT`. |

After curate finishes its edits, the audit file contains only `ACCEPT` and `REJECT`.
Any remaining `MODIFY-AS` is a defect that `curate-approved.ts` surfaces as
`UNRESOLVED_MODIFY_AS`.

## Finding ID Convention

Finding IDs are globally unique across scouts in a cycle via per-scout prefixes:

| Scout mode | Prefix | Example |
|---|---|---|
| `convergence-scout` | `CF-` | `CF-1`, `CF-2`, ... |
| `divergence-scout` | `DF-` | `DF-1`, `DF-2`, ... |
| `primitives-scout` | `PF-` | `PF-1`, `PF-2`, ... |

`curate-approved.ts` enforces global uniqueness via `FINDING_ID_COLLISION`; the
prefixing convention makes collisions impossible by construction.

## Recovery

Interrupted-commit recovery is implicit:

1. Every return carries a `Commit:` field (hash on success, `skipped` for no-diff,
   `failed` if the commit raised an error, `none` if no artifact was written).
2. A return without `Commit:` (or a missing return) is the orchestrator's signal to
   re-dispatch the same invocation. The orchestrator does not inspect git history.
3. Every mode's write workflow is idempotent under re-dispatch:
   - Scouts overwrite the single findings file from scratch; a partial prior write is
     normalized (untracked orphan removed; tracked HEAD restored) before the fresh
     write.
   - Curate's `*-original.md` archives use a "skip if exists" rule, the in-place
     MODIFY-AS edits are content-idempotent (re-applying the same correction to an
     already-`ACCEPT` verdict is a no-op), and `curate-approved.ts` is deterministic.
4. Re-dispatch after a `Commit: failed` return is also safe — the normalize step on the
   re-dispatch clears the uncommitted write, and the re-execution produces a fresh
   coherent commit.

Bootstrapped pipeline scripts (`find-call-sites.ts`, `inventory-utils.ts`,
`curate-approved.ts`) are included in the bootstrapping mode's path-scoped commit when
the bootstrap fired this invocation, so writer == committer holds for the script write
as well.

## Guarantees

- Every write lands inside `.project/cycles/<slug>/refactor-proposals/` (or, when a pipeline
  script bootstrap fires this invocation, `.project/pipeline/scripts/`) within the worktree where
  pattern-analyst was invoked. No mode runs `git -C <main-root> ...` or any equivalent
  main-side action; artifacts reach main exclusively via `/accept-feature`.
- Every mode commits the artifacts it wrote — path-scoped, via the `commit-to-git`
  skill, with `Agent: pattern-analyst` — as the final workflow step before returning.
  One commit per invocation. The path-scoped form excludes unrelated staged work from
  the commit.
- Every return carries a `Commit:` field. The orchestrator's interrupted-commit recovery
  treats a missing `Commit:` as the signal to re-dispatch the same invocation.
- The write+commit workflow is idempotent under re-dispatch — the second invocation
  reaches the same final state regardless of what the first one left behind. Scout
  findings files are overwritten fresh; curate's archives use "skip if exists"; curate's
  in-place edits are content-idempotent; `curate-approved.ts` is deterministic.
- Read-only with respect to application code. No mode modifies source files; proposals
  are emitted as findings.
- Each scout mode is the sole writer of its own findings file. No mode reads or appends
  to another scout's findings file. No append protocol exists anywhere.
- `curate` is the only mode permitted to mutate audit verdicts after the auditor has
  written them, and the only mode permitted to revise findings files post-scout.
- `MODIFY-AS` verdicts always become `ACCEPT` after curate resolution; `REJECT` is final
  and is never altered.
- Every ABSTRACT finding with `verdict: APPROVE` carries the full structured payload
  required by `references/abstract-migration.md`. Plan-architect enforces this as a
  hard-gate precondition.
- `find-call-sites.ts` is run by `convergence-scout` in the scout-and-refactor flow and
  by `primitives-scout` in the primitives flow — single owner per flow. Plan-architect
  never re-runs it.
- `inventory-utils.ts` is bootstrapped by `divergence-scout` in the scout-and-refactor
  flow (with `convergence-scout` as read-only consumer running second) and by
  `primitives-scout` in the primitives flow.
- Finding IDs are globally unique across scouts via the `CF-` / `DF-` / `PF-` prefix
  convention. `curate-approved.ts` enforces uniqueness via `FINDING_ID_COLLISION`.
- The orchestrator owns the slug; pattern-analyst never infers the slug from filesystem
  state. Missing `slug:` produces `Status: ESCALATE, Reason: MISSING_SLUG`.
- When `curate` produces zero `ACCEPT` findings, `pattern-approved.md` still exists with
  the `NO_PROPOSALS_APPROVED` marker so the orchestrator can route the cycle to ship as
  a no-op.
- Frontend script invocations check `.svelte-kit/tsconfig.json` and run
  `svelte-kit sync` (or stack equivalent) when the generated tsconfig is missing.
