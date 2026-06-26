# Pattern Analyst Auditor Guide

## What It Does

The Pattern Analyst Auditor verifies every finding produced by `pattern-analyst` for a single scout-and-refactor or primitives cycle. It re-reads every cited `file:line`, re-applies the ABSTRACT decision matrix against the finding's embedded evidence, checks structured-finding completeness, validates call-site arithmetic, and emits one combined audit file with per-finding `ACCEPT` / `REJECT` / `MODIFY-AS` verdicts — preventing wasted curate and plan-architect effort on findings whose citations or matrix verdicts cannot be trusted.

**Model:** Claude Sonnet (`claude-sonnet-4-6`).

**Input:** A single `slug` field identifying the cycle subdirectory under `.project/cycles/<slug>/refactor-proposals/`.

**Output:** A `Status: COMPLETE` summary inline (counts of `ACCEPT` / `REJECT` / `MODIFY-AS`, plus a `Commit:` field) and a combined audit file at `.project/cycles/<slug>/refactor-proposals/pattern-audit.md`, committed path-scoped via `commit-to-git` before the auditor returns.

### Key points

- **Audit-only.** Never modifies findings files, never modifies the application codebase, never executes pipeline scripts. The only write is the combined `pattern-audit.md`.
- **Worktree-side committer.** The auditor commits its own audit file path-scoped in the refactor/primitives worktree as the final workflow step, then returns with a `Commit:` field (hash, `skipped`, or `failed`). The commit is in the worktree only; it reaches main via `/accept-feature`'s merge.
- **Tool-backed.** Every citation is re-read; every ABSTRACT verdict is re-derived by re-applying the matrix from `.claude/agents/pattern-analyst/references/abstract-migration.md`.
- **Cycle-scoped.** One run per cycle subdirectory; produces one combined audit covering every findings file present (e.g., convergence + divergence in the scout-and-refactor flow; bare `pattern-findings.md` in primitives).
- **Three verdicts.** `ACCEPT` (correct as written), `REJECT` (fundamental defect; final), `MODIFY-AS:<corrected-shape>` (one field needs editing; curate salvages).
- **Worktree-side.** Runs inside the refactor or primitives worktree. Never touches `ROADMAP.md` or files under `.project/product/cycles-in-progress/`.

## When It Runs

Invoked by `orchestrator` after `pattern-analyst` scout modes complete and before `pattern-analyst` `curate` mode runs:

```
pattern-analyst (scout modes) → pattern-analyst-auditor → pattern-analyst (curate) → plan-architect
```

In the scout-and-refactor flow, that means after both `divergence-scout` and `convergence-scout` have written their findings files; in the primitives flow, after `primitives-scout` has written its single findings file.

The audit is the single chokepoint between scouts producing findings and curate consuming them.

## Audit Posture

The auditor adopts a strict, by-the-book posture by design. It defaults to doubt: every finding is suspect until each applicable check has been run against it. An `ACCEPT` verdict is earned by coverage, not by skimming the finding's own `verdict` field. ABSTRACT candidates get the full five-sub-check treatment with the matrix re-applied from scratch — pattern-analyst's verdict claim is one piece of evidence, not the conclusion.

The auditor never inflates a verdict (`ACCEPT` does not creep into edge cases when the citation is questionable) and never invents a corrected shape it cannot ground in tool output. When the evidence does not support a verdict, the auditor emits `REJECT` with a one-to-three-sentence reason.

## Dispatch Contract

The orchestrator provides one field:

| Field | Format | Required |
|-------|--------|----------|
| `slug` | `<DD-MM-YYYY>-refactor-from-<parent-name>` or `<DD-MM-YYYY>-primitives` | Yes |

The orchestrator owns the slug. The auditor never infers it from filesystem state; a missing or malformed slug short-circuits to `Status: INVALID_DISPATCH`.

## What Gets Checked

### Non-ABSTRACT directives (CREATE, EXTRACT, REUSE, REMOVE, RELOCATE, others)

| Check | Outcome on failure |
|-------|--------------------|
| Citation `file:line` resolves at HEAD | `REJECT` — "citation does not resolve" |
| Proposed signature matches cited variants | `REJECT` — names the mismatch |
| SRS citation resolves (primitives-scout findings only) | `REJECT` — "SRS citation does not resolve: <path>" |
| CREATE target does not already exist in inventory | `MODIFY-AS:REUSE` with the existing target's path |

### ABSTRACT directives — five sub-checks

| Sub-check | What it verifies | Outcome on failure |
|-----------|------------------|--------------------|
| A. Completeness | All required fields present per the verdict-conditional structured-finding contract | `REJECT` — names each missing field |
| B. Source citation | `source-file` resolves and `source-function` is defined within it | `REJECT` — "source-function not found in source-file" |
| C. Matrix re-application | Re-derives hard gates and scoring axes against the finding's evidence | `MODIFY-AS:<corrected-verdict>` (overall verdict differs) or `MODIFY-AS:<corrected-sub-check-label>` (one cell differs) |
| D. Call-site arithmetic | `total == .ts + .svelte + uncertain` and `sites` list length equals `total` | `REJECT` — "call-site arithmetic inconsistent" |
| E. Phase-split rule | `phase-splitting-recommendation` matches the coverage band (≥80% → one-phase; 50%–80% → two-phase; <50% should not be APPROVE) | `MODIFY-AS:<corrected-recommendation>` or `REJECT` (when coverage <50% and verdict is APPROVE) |

Sub-checks apply in order; the first failure determines the verdict and later sub-checks are not run for that finding.

The matrix re-application step loads `.claude/agents/pattern-analyst/references/abstract-migration.md` on-demand — it is not preloaded at agent start.

## Understanding the Audit File

Path: `.project/cycles/<slug>/refactor-proposals/pattern-audit.md`

One verdict block per finding, in the order verified:

```
## Verdict: <finding-id>
Origin: <findings-file-path>
Verdict: ACCEPT | REJECT | MODIFY-AS:<corrected-shape>
Reasoning: <text>
```

- `<finding-id>` is the ID assigned by pattern-analyst (`CF-` for convergence, `DF-` for divergence, `PF-` for primitives).
- `Origin:` is repo-relative and tells curate which findings file contains the finding (essential when more than one findings file is in play).
- `Reasoning:` cites the specific check that drove the verdict and the evidence.

The audit file path is fixed — no attempt numbering. If curate revises the audit later, it archives the auditor-produced version to `pattern-audit-original.md` in the same directory before editing in place.

## Commit Behavior

The auditor commits its own audit file path-scoped via `commit-to-git` as the final workflow step. One commit per invocation, naming only `pattern-audit.md`. Subject convention:

| Path | Subject |
|------|---------|
| `.project/cycles/<slug>/refactor-proposals/pattern-audit.md` (normal cycle) | `audit(<slug>): refactor findings audit` |
| `.project/cycles/INVALID/refactor-proposals/pattern-audit.md` (MISSING_SLUG short-circuit) | `audit(INVALID): refactor findings audit` |

The return message carries a `Commit:` field reporting the outcome:

| Value | Meaning |
|-------|---------|
| `<short-hash>` | Commit succeeded; the audit is in HEAD on the worktree branch |
| `skipped` | The commit was a no-op (re-dispatch produced byte-identical content; typical when a complete prior write was detected at HEAD on the recovery path) |
| `failed` | The write succeeded but the commit raised an error (lock contention, hook rejection, transient error); the audit file is on disk but not in HEAD. The orchestrator may re-dispatch |

The auditor always writes a file (either the full audit, the MISSING_SLUG single-verdict shortcut, or the NO_FINDINGS single-verdict shortcut), so `Commit: none` is never returned — the only outcomes are a hash, `skipped`, or `failed`.

## Interrupted-Commit Recovery

If a dispatch ends before the auditor's `Commit:` field is returned — process killed, max-turns hit, hook-blocked stop, transient error after the write but before the commit — the orchestrator re-dispatches the same invocation. The auditor's recovery is built into the write+commit workflow itself; no separate Resume mode exists.

Three branches handle the recovery cases:

1. **Detect prior complete write.** Step 5 first checks whether `pattern-audit.md` exists at the slug's cycle subdirectory. If yes, Write atomicity guarantees the file is a complete prior-attempt write — the auditor parses its verdict blocks for counts and return status, skips the full citation-verification and matrix-reapplication work, and proceeds straight to commit. This saves the LLM cost of re-running the audit.
2. **Normalize when absent.** If `pattern-audit.md` is absent, Step 5 runs a normalize-to-HEAD-or-remove pass before writing fresh (tracked → `git checkout HEAD -- <path>`; untracked → `rm -f`; absent → no-op). This clears any partial orphan from a crashed prior write.
3. **Path-scoped commit.** Step 6 commits the audit file alone, never sweeping in other staged work.

Re-dispatching after `Commit: failed` is safe: the file already exists, so the next attempt enters the detect-prior-complete-write branch and produces either a fresh hash or `Commit: skipped` if the path now matches HEAD.

## Verdict Semantics

| Verdict | Meaning | What curate does |
|---------|---------|------------------|
| `ACCEPT` | Finding is correct as written | Passes through to `pattern-approved.md` |
| `REJECT` | Finding has a fundamental defect (missing required field, broken citation, broken arithmetic, coverage below the hard-gate floor) | Dropped. `REJECT` is final |
| `MODIFY-AS:<corrected-shape>` | Finding is structurally intact but one field needs editing | Curate edits the named field, converts the audit verdict to `ACCEPT`. Never escalates to `REJECT` |

The distinction between `REJECT` and `MODIFY-AS:verdict=REJECT` matters:

- `REJECT` means the finding cannot be salvaged without pattern-analyst rewriting it (missing fields, broken arithmetic, broken citations).
- `MODIFY-AS:verdict=REJECT` means the finding is structurally complete and well-cited, but the matrix re-application disagrees with the `verdict: APPROVE` claim. Curate edits the finding's internal `verdict` field to `REJECT`; `curate-approved.ts` then drops it from `pattern-approved.md`.

Both outcomes drop the finding from the approved set; the difference is whether the finding's structural metadata is salvageable (the `MODIFY-AS` path preserves it for transparency in `pattern-audit-original.md`).

## Returns

| Status | When | Action for caller |
|--------|------|-------------------|
| `COMPLETE` | Audit ran end-to-end; one verdict per finding emitted | Orchestrator dispatches `pattern-analyst` (`curate` mode) next |
| `INVALID_DISPATCH` | `slug` missing or malformed | Orchestrator escalates to user; do not dispatch curate |
| `NO_FINDINGS` | Cycle subdirectory has no current `pattern-findings*.md` files | Orchestrator escalates — the cycle is unexpectedly empty |

Every return also carries a `Commit:` field. Its absence (or missing return message) is the orchestrator's interrupted-commit recovery signal — it re-dispatches the same invocation, and the auditor's idempotent write+commit workflow produces a clean commit on the second attempt.

## Limitations

- **Bounded Bash allowlist.** The auditor uses Bash only for: `mkdir -p` on the cycle subdirectory, `echo` to register the SubagentStop output target, `git ls-files`/`git checkout HEAD --`/`rm -f` to normalize the audit path before write, and `git add`/`git commit` (path-scoped, via the `commit-to-git` skill) to commit the audit file. Any other Bash invocation is out of scope.
- **Verdict-only on findings files.** The auditor never edits findings; corrections happen in `curate`. A `MODIFY-AS` verdict is a proposal for curate, not an executed change.
- **Pipeline-script-blind.** The auditor reads `call-site-data` from the finding rather than re-running `find-call-sites.ts`. If pattern-analyst's call-site data is internally inconsistent (arithmetic broken), the auditor catches it via Sub-check D, but it does not re-derive the figures from scratch.
- **Cycle-scoped.** Runs against exactly one cycle subdirectory per dispatch. Cross-cycle consistency (e.g., the same finding appearing under different IDs across cycles) is out of scope.
- **Heuristic non-ABSTRACT signature check.** "Signature matches cited variants" relies on the auditor reading the cited source; subtle type-level discrepancies that the auditor cannot resolve via Read/Grep alone may slip through. `code-reviewer` (`ABSTRACT_MIGRATION_REVIEW` mode) catches signature drift at implementation time.
- **No interactive escalation.** The auditor never asks the user. Ambiguous findings produce a verdict (or `REJECT` with reasoning) — never a question.
- **Intentional cross-agent file dependency.** Sub-check C reads `.claude/agents/pattern-analyst/references/abstract-migration.md`, which lives inside `pattern-analyst`'s private `references/` directory. This coupling is by design — the abstraction decision matrix is the single source of truth for `pattern-analyst`'s ABSTRACT-candidate evaluation, and the auditor's job is to re-apply the same matrix to verify the result. Moving the matrix to a shared location would invert ownership (pattern-analyst owns ABSTRACT decisions; the matrix is its decision logic). Both agents must remain in lockstep when the matrix changes.

## How to Extend

### Adding a new finding directive type

1. Add the new directive's verification rules to the "Non-ABSTRACT directives" subsection in `pattern-analyst-auditor.md` (under "Step 4 — Verify each finding").
2. Update the contract's "Verification Coverage" table.
3. If the new directive requires verdict-conditional fields, add a Sub-check A counterpart.

### Adding a new ABSTRACT sub-check

1. Add it as a numbered sub-check in `pattern-analyst-auditor.md` under "ABSTRACT directives — strict structured verification".
2. Update the contract's "Verification Coverage" table.
3. If the sub-check has a corresponding entry in `.claude/agents/pattern-analyst/references/abstract-migration.md`, make sure that file is updated in lockstep (the agent loads that file at Sub-check C).

## Related

- Agent definition: `.claude/agents/pattern-analyst-auditor/pattern-analyst-auditor.md`
- Interface contract: `.claude/agents/interface-contracts/pattern-analyst-auditor.contract.md`
- Pattern-analyst (produces the findings this agent verifies): `.claude/agents/pattern-analyst/pattern-analyst.md`
- ABSTRACT decision matrix (loaded on-demand): `.claude/agents/pattern-analyst/references/abstract-migration.md`
- Pattern-analyst guide: `pattern-analyst.guide.md`
- Curate-approved.ts (consumes the audit downstream via curate): `.project/pipeline/scripts/curate-approved.ts`
- Orchestrator (dispatches this agent): `.claude/skills/orchestrator/SKILL.md`
