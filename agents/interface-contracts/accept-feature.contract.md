# accept-feature Interface Contract

Slash-skill that promotes a completed cycle (feature, refactor, primitives, or bugfix) to approved, merges its worktree branch into main, delegates ROADMAP teardown to `progress-tracker close --final-status=completed`, and — when the close output carries `MilestoneCompleted: v<X.Y>` — instructs the main agent (the one that invoked this skill) to run the `quality-analyst` milestone fan-out (scoped per-(cycle × target) runs, then a `Mode: synthesis` roll-up) and then dispatch `milestone-archivist`, in that order. Invoked by the user (slash command) or by `orchestrator` (Skill tool).

## Input

Single positional argument identifying the cycle to accept. Optional — if omitted, the skill prompts the user to pick from active cycles.

### Argument forms

| Form | Example | Resolves to |
|---|---|---|
| Feature slug | `19-04-2026-pdf-extraction` | Worktree leaf `19-04-2026-pdf-extraction`; ROADMAP entry `19-04-2026-pdf-extraction` |
| Refactor slug | `19-04-2026-refactor-from-pdf-extraction` | Worktree leaf `19-04-2026-refactor-from-pdf-extraction`; ROADMAP entry `19-04-2026-refactor-from-pdf-extraction` (always present from pre-curate start) |
| Primitives slug | `19-04-2026-primitives` | Worktree leaf `19-04-2026-primitives`; ROADMAP entry of the same name (always present from pre-curate start) |
| Bugfix slug | `19-04-2026-fix-hebrew-date-parse-crash` | Worktree leaf `19-04-2026-fix-hebrew-date-parse-crash`; ROADMAP entry `19-04-2026-fix-hebrew-date-parse-crash` |
| Feature-directory path | `.project/cycles/19-04-2026-pdf-extraction/` | Feature slug extracted from the leaf |
| (omitted) | — | Skill globs active cycles and prompts the user |

The worktree-type is resolved from the matched ROADMAP entry's authoritative `Type:` field (`feature | refactor | primitives | bugfix`), never inferred from the slug prefix.

### Preconditions

- The ROADMAP `### <slug>` entry must exist; its `Type:` field supplies the worktree-type (`feature | refactor | primitives | bugfix`), never inferred from the slug prefix — a feature slug beginning `fix-` is therefore never misread as a bug fix. A missing entry returns `Status: ERROR` (entry-not-found); the type is never guessed.
- For `feature`, the entry's `Status` must be `completed-pending-approval`. Anything else returns `Status: ERROR`.
- For `refactor`, the entry's `Status` must be `completed-pending-approval` — both close-out paths reach this state before handing back to the skill (the orchestrator dispatches `progress-tracker ship` on both `APPROVED_PROPOSALS_EXIST` post-phase completion and `NO_PROPOSALS_APPROVED` empty close-out). The entry's `Stage` distinguishes the close-out path: `Stage: post-curate` is the approved path (cycle ran through phases); `Stage: pre-curate` is the empty path (curate returned `NO_PROPOSALS_APPROVED`, no phases ran). Anything other than `completed-pending-approval` returns `Status: ERROR`.
- For `primitives`, the entry always exists from pre-curate start; its `Status` must be `completed-pending-approval`. `Scout-Result` is `n/a` — a primitives cycle closes identically whether or not it approved proposals, so the approved-vs-empty outcome is not recomputed at accept. Anything other than `completed-pending-approval` returns `Status: ERROR`.
- For `bugfix`, the entry's `Status` must be `completed-pending-approval` (the bugfix lifecycle goes through `progress-tracker ship` before accept). Anything else returns `Status: ERROR`.
- The worktree at `.worktrees/<leaf>/` must exist.

### Example invocations

```
/accept-feature 19-04-2026-pdf-extraction
```

```
/accept-feature 19-04-2026-refactor-from-pdf-extraction
```

```
/accept-feature 19-04-2026-primitives
```

```
/accept-feature 19-04-2026-fix-hebrew-date-parse-crash
```

## Output

The skill returns a structured user-facing report to the caller (or main agent). The shape:

```
Cycle <slug> accepted.
Worktree-Type: <feature | refactor | primitives | bugfix>
Scout-Result: <n/a | approved | empty>
Status: completed-pending-approval -> completed
Merge: <merged | already merged | no-op (no ROADMAP entry)>
Tracking file: <deleted | n/a>
ROADMAP commit: <short-hash | n/a>
```

The `Worktree-Type` value mirrors the input passed to `progress-tracker close`. The `<slug>` on the first line is always the cycle's primary slug — feature slug for `feature`, refactor slug for `refactor`, primitives slug for `primitives`, bugfix slug for `bugfix`.

Appended sections depend on the close output and cleanup outcome.

### Section: Milestone follow-up (appears iff `MilestoneCompleted: v<X.Y>` fired)

```
Milestone v<X.Y> completed.

Next steps (for the main agent that invoked this skill):
  1. Run the quality-analyst milestone fan-out (quality-analyst has no milestone mode —
     the dispatcher owns the fan-out; see quality-analyst.contract.md):
     a. For each completed cycle in the milestone, dispatch one scoped quality-analyst run per
        (cycle x target): Mode: agent (Target, Cycle Path) or Mode: skill (Target, Cycle Path).
     b. Then dispatch one quality-analyst Mode: synthesis, Scope: milestone v<X.Y> — it writes
        both the milestone synthesis report and
        .project/pipeline/quality-reports/<DD-MM-YYYY>-v<X.Y>-knowledge-usage-report.md.
  2. Dispatch milestone-archivist with Milestone: v<X.Y> and these cycle-summary paths:
     - .project/cycles/<dir-1>/execution/state/cycle-summary.md
     - .project/cycles/<dir-2>/execution/state/cycle-summary.md
     ...
     (The path-scoped archival commit picks up the new quality report alongside the milestone snapshot.)

Dispatch in that order — the quality-analyst fan-out and synthesis first, then milestone-archivist.
```

The caller must read this section and run the fan-out and synthesis, then dispatch milestone-archivist, in the listed order. The skill itself does NOT spawn `quality-analyst` or `milestone-archivist`; it computes and supplies the cycle inputs.

### Section: Cleanup outcome (appears iff worktree cleanup ran)

```
Worktree: removed | kept
Branch: deleted | retained
```

### Error returns

| Condition | Behavior |
|---|---|
| Worktree missing | Returns `Status: ERROR` with the missing path; no mutations. |
| ROADMAP `### <slug>` entry missing | Returns `Status: ERROR` (entry-not-found); the worktree-type is never inferred from the slug prefix. No mutations. |
| ROADMAP entry's state does not match the worktree-type's preconditions (see § Preconditions) | Returns `Status: ERROR` with the actual status (and `Stage` for refactor entries); no mutations. |
| Merge conflict on non-`.project/product/` paths | Aborts the merge, surfaces the conflicting paths, stops before delegating to `progress-tracker close`. |
| `progress-tracker close` returns `ERROR` | Surfaces the failure to the caller. Merge may have already landed; re-running is safe (close is idempotent on a missing tracking file). |
| Missing `cycle-summary.md` for any milestone entry on a milestone-completion path | Reports the missing summary and stops before instructing milestone follow-up. |

## Guarantees

- **Atomic merge** via `git merge --no-ff`. The skill never edits the worktree's working tree.
- **No tagging.** Tag creation is owned by `milestone-archivist`. The skill never creates or pushes git tags directly.
- **Sole writer of merges to main** for completed cycles — but never of ROADMAP or tracking files. All ROADMAP/tracking writes are delegated to `progress-tracker close`.
- **Milestone follow-up is advisory, not dispatched.** The skill computes the cycle-summary paths and returns them in the report; the main agent runs the `quality-analyst` milestone fan-out (scoped per-(cycle × target) runs, then a `Mode: synthesis` roll-up) and then dispatches `milestone-archivist`.
- **Idempotent.** Re-running after a partial failure produces the same final state without spurious commits.
- **Worktree cleanup is opt-in** via `AskUserQuestion` and uses `git branch -d` (refuses unmerged branches).
- **Generalized across worktree types** — feature, refactor, primitives, and bugfix flows share the same workflow steps; behavior diverges only in worktree-type detection (the entry's `Type:` field) and the `Worktree-Type` / `Scout-Result` / `Parent-Feature` fields passed to `progress-tracker close`.

## Relationship to other agents/skills

- **Invoked by:** the user (slash command), or `orchestrator` skill (Skill tool, post-merge promotion path).
- **Invokes (via Agent tool):** `progress-tracker` (always, in `close` mode). The skill never spawns `quality-analyst` or `milestone-archivist`; the main agent runs the `quality-analyst` fan-out + synthesis and then dispatches `milestone-archivist` per the milestone follow-up section above.
- **Reads** `.claude/agents/interface-contracts/progress-tracker.contract.md` to construct the close input.
- **Never invoked by:** any worktree-side agent.
