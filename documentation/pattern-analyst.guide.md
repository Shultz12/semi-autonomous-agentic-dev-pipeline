# Pattern Analyst - User Guide

## What It Does

The Pattern Analyst detects refactor opportunities across the codebase, evaluates ABSTRACT candidates against a hard-gate + scoring-axis matrix, and curates the per-cycle approved findings file that plan-architect's `refactor-plan` target consumes. It operates in one of four modes selected by dispatch:

- **convergence-scout** — finds duplicated logic (3-layer detection: regex / jscpd / inline semantic); proposes EXTRACT or evaluates ABSTRACT.
- **divergence-scout** — finds places the merged feature reimplemented inline instead of using an existing primitive or convention; proposes REUSE.
- **primitives-scout** — finds shared utilities needed by ≥2 accepted SRSes; proposes CREATE or evaluates ABSTRACT.
- **curate** — resolves `MODIFY-AS` audit verdicts and produces the cycle's `pattern-approved.md`.

Every mode commits the artifacts it wrote — path-scoped, via the `commit-to-git` skill — as its final step before returning. The return carries a `Commit:` field so the orchestrator can apply interrupted-commit recovery if the field is missing.

**Model:** `sonnet`

**Invocation:** Orchestrator-dispatched only — not user-invocable. The orchestrator passes `Mode:` + `slug:` per cycle.

**Pipeline position:**
```
post-merge scout-and-refactor flow:
  divergence-scout → convergence-scout → pattern-analyst-auditor → curate
                                              ↓
                                      pattern-approved.md → plan-architect (refactor-plan)

primitives flow:
  primitives-scout → pattern-analyst-auditor → curate
                          ↓
                  pattern-approved.md → plan-architect (refactor-plan)
```

**Sole owner of ABSTRACT decisions across the pipeline.** No other agent re-evaluates ABSTRACT viability or re-runs `find-call-sites.ts`.

---

## When It Runs

Three triggering conditions, all orchestrator-driven:

| Trigger | Flow | Worktree |
|---------|------|----------|
| Feature merged to main, post-merge refactor cycle requested | scout-and-refactor | `<DD-MM-YYYY>-refactor-from-<parent-name>` |
| ≥2 accepted SRSes exist in `.project/cycles/` and user requests a primitives cycle | primitives | `<DD-MM-YYYY>-primitives` |
| Auditor has emitted `pattern-audit.md` and curate is needed | either | same worktree as the pre-curate scout modes |

You don't invoke pattern-analyst directly. You invoke the orchestrator skill, which runs the cycle.

---

## Output Layout

All artifacts for a cycle live in `.project/cycles/<slug>/refactor-proposals/`:

| File | Written by | Purpose |
|---|---|---|
| `pattern-findings-convergence.md` | `convergence-scout` | Convergence findings (CF-1, CF-2, ...) |
| `pattern-findings-divergence.md` | `divergence-scout` | Divergence findings (DF-1, DF-2, ...) |
| `pattern-findings.md` | `primitives-scout` | Primitives findings (PF-1, PF-2, ...) |
| `pattern-audit.md` | `pattern-analyst-auditor` | Per-finding verdicts (ACCEPT/REJECT/MODIFY-AS) |
| `*-original.md` | `curate` | Immutable archives, created when curate revises a findings file or the audit |
| `pattern-approved.md` | `curate` (via `curate-approved.ts`) | Final approved findings consumed by plan-architect |

---

## Finding Directives

| Directive | Emitted by | Meaning |
|---|---|---|
| EXTRACT | convergence-scout | Consolidate a duplicated cluster into a new shared utility |
| ABSTRACT | convergence-scout, primitives-scout | Generalize an existing narrow utility (full structured payload) |
| REUSE | divergence-scout | Replace a divergent inline implementation with an existing utility or convention |
| CREATE | primitives-scout | Create a new shared utility required by ≥2 accepted SRSes |
| REMOVE | any scout mode | Drop unused/superseded code (rare) |
| RELOCATE | any scout mode | Move a utility to its correct architectural location (rare) |

---

## Verdict Doctrine

The auditor emits one of three verdicts per finding:

| Verdict | Curate action |
|---|---|
| `ACCEPT` | Pass through to `approved.md` |
| `REJECT` | Drop from `approved.md`. **Final** — curate never alters `REJECT`. |
| `MODIFY-AS:<corrected-shape>` | Curate edits the finding AND changes the verdict to `ACCEPT`. Always becomes `ACCEPT`, never `REJECT`. |

After curate finishes, the audit file contains only `ACCEPT` and `REJECT`.

---

## Commit Behavior

Every mode commits its artifacts path-scoped via the `commit-to-git` skill as the final
workflow step. The subject convention is:

| Mode | Subject |
|---|---|
| `convergence-scout` | `refactor(<slug>): convergence findings` |
| `divergence-scout` | `refactor(<slug>): divergence findings` |
| `primitives-scout` | `refactor(<slug>): primitives findings` |
| `curate` | `refactor(<slug>): curate approved` |

Each mode's commit covers every project-level path it wrote this invocation:

- Scouts commit their single findings file. If the mode bootstrapped a pipeline script
  (`find-call-sites.ts`, `inventory-utils.ts`) this invocation, the script's project
  copy is also in the commit.
- `curate` commits `pattern-approved.md` always; plus any findings file edited to
  resolve a `MODIFY-AS`, the in-place edited `pattern-audit.md`, the corresponding
  `*-original.md` archives, and (rarely) the `curate-approved.ts` project copy if
  bootstrapped this invocation.

The return carries a `Commit:` field:

| Value | Meaning |
|---|---|
| `<short-hash>` | Mode-final commit succeeded path-scoped to the worktree. |
| `skipped` | All paths matched HEAD byte-for-byte; no empty commit was forced. |
| `failed` | Write succeeded but the commit raised an error. Artifacts are on disk; treat as recoverable failure. |
| `none` | No artifact was written this invocation (ESCALATE before any write). |

## Interrupted-Commit Recovery

If a mode dies after writing artifacts but before committing (process killed, max-turns
hit, transient error, hook-blocked stop), the orchestrator sees a missing `Commit:`
field (or a missing return) and re-dispatches the same invocation. Recovery is implicit:

1. Each mode's write workflow includes a "normalize each target file to HEAD" step
   before any fresh write — uncommitted partial writes from the prior dispatch are
   discarded (`git checkout HEAD -- <path>` for tracked paths, `rm -f <path>` for
   orphan untracked files).
2. The re-dispatched invocation writes fresh content and produces a new path-scoped
   commit. If the regenerated content matches HEAD byte-for-byte, the return is
   `Commit: skipped`; otherwise `Commit: <hash>`.
3. Curate's `*-original.md` archives use a "skip if exists" rule, and its in-place
   MODIFY-AS edits are content-idempotent — re-applying a correction to a verdict
   already changed to `ACCEPT` is a no-op.

The orchestrator does not inspect git history to verify what happened on the prior
attempt; the return-message presence on the next attempt is the sufficient signal.

## What It Won't Do

| Limitation | Reason |
|---|---|
| Modify application code | Read-only with respect to the codebase; migration is plan-architect + developer's job |
| Write outside `.project/cycles/<slug>/refactor-proposals/` (or `.project/pipeline/scripts/` for a fresh bootstrap) | Strict per-cycle subdirectory write boundary; bootstraps are the one project-wide write, included in the writer's own commit |
| Re-evaluate or alter another scout mode's findings mid-cycle | Sole-writer-per-file rule; curate is the only post-write mutator |
| Commit to main or push | Worktree-isolated; artifacts reach main only via `/accept-feature` |
| Prompt the user directly | Failures escalate to the orchestrator via `Status: ESCALATE` |
| Stage or commit files outside the mode's path set | Path-scoped commit form keeps unrelated staged work in the index out of the commit |

---

## Related Documentation

- **Agent definition:** `.claude/agents/pattern-analyst/pattern-analyst.md`
- **Interface contract:** `.claude/agents/interface-contracts/pattern-analyst.contract.md`
- **ABSTRACT matrix reference:** `.claude/agents/pattern-analyst/references/abstract-migration.md`
- **Pipeline scripts skill:** `.claude/skills/use-pipeline-scripts/SKILL.md`
- **Auditor guide:** `pattern-analyst-auditor.guide.md` (paired auditor)
- **Plan Architect guide:** [plan-architect.guide.md](plan-architect.guide.md) — consumes `pattern-approved.md` via `refactor-plan` target
