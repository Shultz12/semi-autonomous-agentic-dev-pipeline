# pattern-analyst-auditor Interface Contract

## Input

The caller provides one required field in the prompt:

```
slug: <DD-MM-YYYY>-refactor-from-<parent-name> | <DD-MM-YYYY>-primitives
```

The orchestrator owns the slug — it created the worktree and the cycle subdirectory at `.project/cycles/<slug>/refactor-proposals/`. Do not omit `slug`; the auditor never infers it from filesystem state.

**Example — scout-and-refactor cycle:**

```
Verify the pattern-analyst findings for this cycle.
slug: 19-04-2026-refactor-from-user-auth
```

**Example — primitives cycle:**

```
Verify the pattern-analyst findings for this cycle.
slug: 19-04-2026-primitives
```

## Output

The auditor is a worktree-side committer: it writes the combined audit file and commits that file path-scoped via `commit-to-git` before returning. Every return carries a `Commit:` field so the orchestrator can apply interrupted-commit recovery if needed.

### Direct Return

#### COMPLETE (Success)

```
Status: COMPLETE
Slug: [slug]
Audit: .project/cycles/[slug]/refactor-proposals/pattern-audit.md
Findings audited: [N] across [M] source files
Verdicts: [A] ACCEPT, [R] REJECT, [X] MODIFY-AS
Commit: [short-hash | skipped | failed]
```

#### INVALID_DISPATCH (Caller error)

Returned when `slug` is missing or malformed. The audit file is still written (with a single CRITICAL `MISSING_SLUG` verdict) under `.project/cycles/INVALID/refactor-proposals/` so the SubagentStop hook is satisfied, and is committed path-scoped.

```
Status: INVALID_DISPATCH
Slug: missing | <malformed-value>
Audit: [path written]
Reason: missing slug in dispatch | slug format does not match expected shape
Commit: [short-hash | skipped | failed]
```

#### NO_FINDINGS (Empty cycle)

Returned when the cycle subdirectory contains no current `pattern-findings*.md` files (excluding `*-original.md` archives). The audit file is written with a single CRITICAL `NO_FINDINGS_FILES_PRESENT` verdict and committed.

```
Status: NO_FINDINGS
Slug: [slug]
Audit: [path written]
Reason: no findings files present in cycle subdirectory
Commit: [short-hash | skipped | failed]
```

#### FAILED (Infrastructure error)

Returned when an infrastructure failure prevents normal verification — e.g., a `pattern-findings*.md` file cannot be Read despite Glob enumerating it, `references/abstract-migration.md` cannot be loaded for matrix re-application, the cycle subdirectory cannot be created or written to, or the normalize step's git operations hit a persistent lock that does not clear within the turn budget. The audit file is still written (with a single CRITICAL `INFRASTRUCTURE_FAILURE` verdict) and committed path-scoped when the underlying failure is not git-side; otherwise `Commit: failed` is returned.

```
Status: FAILED
Slug: [slug] | unknown
Audit: [path written]
Reason: [text describing the infrastructure failure mode]
Commit: [short-hash | skipped | failed]
```

`FAILED` is distinct from per-finding `REJECT` verdicts: a `REJECT` records a normal verification outcome (citation broken, matrix says REJECT, structural defect), while `FAILED` records that verification itself could not proceed. The orchestrator may re-dispatch on transient failures (git lock contention, transient I/O) or escalate to the user for persistent ones.

### `Commit:` Field Semantics

| Value | Meaning |
|-------|---------|
| `<short-hash>` | Commit succeeded; this is the git short hash of the path-scoped commit naming `pattern-audit.md` |
| `skipped` | The commit was a no-op (regenerated content byte-identical to HEAD — typical when Step 5 recognized a complete prior write at HEAD on an interrupted-commit recovery re-dispatch) |
| `failed` | The write succeeded but the commit raised an error (lock contention, hook rejection, transient error); the file is on disk but not in HEAD. The orchestrator may re-dispatch |

Unlike committing agents that have a "no artifact written" path, every invocation of this auditor writes a file (either the full audit, the MISSING_SLUG single-verdict shortcut, the NO_FINDINGS single-verdict shortcut, or the INFRASTRUCTURE_FAILURE single-verdict shortcut), so `Commit: none` is never returned — the only outcomes are a hash, `skipped`, or `failed`.

### Written Audit File

Written to: `.project/cycles/<slug>/refactor-proposals/pattern-audit.md`

The path is fixed — no attempt numbering. If `pattern-analyst` (`curate` mode) revises the audit later, it archives the auditor-produced version to `pattern-audit-original.md` in the same directory before editing in place.

Structure: one verdict block per finding across all input findings files, in the order verified.

```markdown
## Verdict: <finding-id>
Origin: <findings-file-path>
Verdict: ACCEPT | REJECT | MODIFY-AS:<corrected-shape>
Reasoning: <text>
```

| Field | Type | Description |
|-------|------|-------------|
| `<finding-id>` | string | Finding ID as written by pattern-analyst (e.g., `CF-3`, `DF-1`, `PF-2`) |
| `Origin` | repo-relative path | The source findings file that contains this finding |
| `Verdict` | `ACCEPT` \| `REJECT` \| `MODIFY-AS:<corrected-shape>` | Per-finding judgment |
| `Reasoning` | 1–3 sentences | The check that drove the verdict + the evidence |

## Verdict Semantics

| Verdict | Meaning | What curate does |
|---------|---------|------------------|
| `ACCEPT` | Finding is correct as written | Passes through to `pattern-approved.md` |
| `REJECT` | Finding has a fundamental defect (missing required field, broken citation, broken arithmetic, coverage below hard-gate floor) | Removed from `pattern-approved.md`. `REJECT` is final and is never altered by curate |
| `MODIFY-AS:<corrected-shape>` | Finding is structurally intact but one field needs editing | Curate edits the named field in the findings file and converts the audit verdict to `ACCEPT`. `MODIFY-AS` is never escalated to `REJECT` |

`<corrected-shape>` is parsed by curate. Common shapes:

| Shape | Meaning |
|-------|---------|
| `MODIFY-AS:verdict=REJECT, reason=<text>` | Flip the finding's internal `verdict` field; curate-approved.ts will drop the finding |
| `MODIFY-AS:verdict=APPROVE` | Flip the finding's internal `verdict` from REJECT to APPROVE (requires structural completeness already present) |
| `MODIFY-AS:scoring-axes.<axis>=FAIL` | Correct one sub-check label (e.g., `MODIFY-AS:scoring-axes.shape-congruence=FAIL`) |
| `MODIFY-AS:hard-gates.<gate>.<sub>=FAIL` | Correct one hard-gate sub-check label |
| `MODIFY-AS:phase-splitting-recommendation=<one-phase\|two-phase>` | Correct the phase-split recommendation |
| `MODIFY-AS:REUSE` | Convert a CREATE finding to REUSE with the cited existing target |

## Inputs Read

| Path | Purpose |
|------|---------|
| `.project/cycles/<slug>/refactor-proposals/pattern-findings*.md` | Source findings; enumerated via bounded glob (excludes `*-original.md`) |
| Cited source files in the codebase at HEAD | Verify `file:line` citations and `source-function` definitions |
| `.project/cycles/<slug>/specs/SRS.md` (when cited) | Verify SRS citations on `primitives-scout` findings |
| `.claude/agents/pattern-analyst/references/abstract-migration.md` | Loaded on-demand when verifying any ABSTRACT finding (Sub-check C: matrix re-application) |
| `.claude/skills/commit-to-git/SKILL.md` | Loaded on-demand at Step 6 (commit) to get the path-scoped commit form, `Agent:` trailer, and dual-context rule |

## Verification Coverage

Every finding receives the appropriate check set:

| Finding kind | Checks |
|--------------|--------|
| Non-ABSTRACT directive (CREATE, EXTRACT, REUSE, REMOVE, RELOCATE, etc.) | Citation resolves; proposed signature matches cited variants; SRS citations resolve (primitives-scout); CREATE target does not already exist in inventory |
| ABSTRACT directive | All five sub-checks in order: (A) completeness per verdict-conditional contract, (B) source citation, (C) matrix re-application against `references/abstract-migration.md`, (D) call-site arithmetic, (E) phase-split rule |

## Recovery

The orchestrator detects an interrupted commit via the absence of a `Commit:` field on the return message (or no return at all — process killed, max-turns hit, hook-blocked stop). On detection, it re-dispatches the same invocation with the same slug.

The auditor's recovery mechanism is built into the write+commit workflow itself; no separate Resume mode is needed:

- **Detect-prior-complete-write.** Step 5 checks whether `pattern-audit.md` exists at the slug's cycle subdirectory before re-running any verification work. If yes, Write atomicity guarantees the file is a complete prior-attempt write — the auditor parses its verdict blocks for counts and return status, skips the audit work, and proceeds to commit. This saves the full LLM cost of re-verifying every citation and re-applying the ABSTRACT matrix on the recovery path.
- **Normalize-when-absent.** If `pattern-audit.md` is absent, Step 5 runs a normalize-to-HEAD-or-remove pass on the target path before writing fresh (tracked → `git checkout HEAD -- <path>`; untracked → `rm -f`; absent → no-op).
- **Path-scoped commit.** Step 6 commits the audit file alone, never sweeping in other staged work.

Re-dispatching after `Commit: failed` is safe: the file already exists, so the next attempt enters the detect-prior-complete-write branch and produces either a fresh hash or `Commit: skipped` if the path now matches HEAD.

## Guarantees

- The output file is always written before the auditor returns (SubagentStop completion gate).
- The output file is also committed path-scoped via `commit-to-git` before the auditor returns. The commit is in the worktree only; it never reaches main except via `/accept-feature`'s eventual merge.
- Every return message carries a `Commit:` field (a short hash, `skipped`, or `failed`). The orchestrator uses presence/absence of this field as the interrupted-commit recovery signal.
- The write+commit workflow is idempotent under re-dispatch: a complete prior-attempt write on disk is recognized and committed as-is rather than re-running the audit, and a partial or absent file is normalized to a clean starting state before a fresh write.
- The commit is path-scoped to `.project/cycles/<slug>/refactor-proposals/pattern-audit.md` only; other staged work in the worktree is never swept into the audit's commit.
- The commit attribution trailer carries `Agent: pattern-analyst-auditor` so the history identifies which pipeline role produced the commit.
- Every finding across every `pattern-findings*.md` in the cycle subdirectory receives exactly one verdict block.
- Every verdict block carries an `Origin:` line naming the source findings file (repo-relative).
- ABSTRACT findings are verified by re-applying the abstraction decision matrix from `.claude/agents/pattern-analyst/references/abstract-migration.md`; the finding's `verdict` field is never trusted unchecked.
- Citations are verified via tool calls (Read or Grep against the codebase, Glob for SRS paths); inference about what the finding "probably means" never substitutes for a tool check.
- The auditor is read-only with respect to findings files and the application codebase; the only write is the combined audit file.
- Pipeline scripts (`find-call-sites.ts`, `inventory-utils.ts`, `curate-approved.ts`) are never executed; their data is read from the finding's embedded fields.
- The slug is consumed from the dispatch; the auditor never infers it from filesystem state.
- A `MODIFY-AS:<corrected-shape>` verdict is always intended for `curate` to fix to `ACCEPT`; the auditor never uses `MODIFY-AS` as a soft `REJECT` for fundamental defects (those produce `REJECT` directly).
- The audit file path is fixed at `.project/cycles/<slug>/refactor-proposals/pattern-audit.md` (no attempt numbering); `pattern-analyst` (`curate` mode) archives the prior version to `pattern-audit-original.md` if it needs to revise it.

## Boundary

Audit-only with respect to findings files and code. Writes only one project-level artifact (`pattern-audit.md`) and commits only that one path. Not consumed directly by `plan-architect` — `plan-architect` consumes only `pattern-approved.md` from the curate step. The audit feeds `pattern-analyst` (`curate` mode), which applies `MODIFY-AS` corrections, drops `REJECT`s, and runs `curate-approved.ts` to produce `pattern-approved.md`. Do not bypass curate.

Worktree-side writer and committer: runs inside `.worktrees/<refactor-or-primitives-cycle>/`; the only write is to `.project/cycles/<slug>/refactor-proposals/pattern-audit.md`, and the only commit is the path-scoped commit naming that same file. Never touches `ROADMAP.md` or anything under `.project/product/cycles-in-progress/`, never stages other agents' artifacts, never targets `main`.
