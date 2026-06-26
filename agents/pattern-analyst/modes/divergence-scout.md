# Mode: divergence-scout

Detects divergent code: places where existing primitives/conventions exist but the merged
feature did not use them (reimplemented inline; bypassed; called with wrong invariants).
Runs against the diff between this feature's merge and main, cross-referencing existing
primitives via `inventory-utils.ts` and existing conventions via `_index.md` rows +
bodies. Writes findings to its own file at
`.project/cycles/<slug>/refactor-proposals/pattern-findings-divergence.md`.

## Inputs

```
Mode: divergence-scout
slug: <slug>
```

- The codebase diff between this feature's merge and main.
- `.project/knowledge/architecture.md` — for the `## Shared utility locations` heading
  consumed by `inventory-utils.ts`.
- `.project/knowledge/<type>/_index.md` files — to surface conventions the feature should
  have used.
- Existing primitives via `.project/pipeline/scripts/inventory-utils.ts`. **This mode is the sole
  owner and bootstrapper of `inventory-utils.ts` in the scout-and-refactor flow.**

## Bootstrap Responsibility

- Sole bootstrapper of `inventory-utils.ts` in the scout-and-refactor flow. On first use,
  follow `.claude/skills/use-pipeline-scripts/SKILL.md`'s copy-if-missing protocol.
- Does NOT bootstrap or run `find-call-sites.ts`. This mode's findings concern non-use of
  existing utilities, not generalization of them — ABSTRACT candidates surface in
  `convergence-scout` and `primitives-scout`.

## Dispatch Order

In the scout-and-refactor flow, `divergence-scout` runs FIRST because it owns
`inventory-utils.ts`; `convergence-scout` runs SECOND and consumes the bootstrapped
copy. The two scouts' findings are independent — neither reads the other's output —
but the order is not freely interchangeable.

## Workflow

1. **Register output path** — Bash: `mkdir -p .project/cycles/<slug>/refactor-proposals/ && echo ".project/cycles/<slug>/refactor-proposals/pattern-findings-divergence.md" > /tmp/.claude-agent-output-target`. The `mkdir -p` creates the cycle's `refactor-proposals/` subdirectory at scout-start — for a refactor/primitives cycle `.project/cycles/<slug>/` may not exist yet.

2. **Read context** — Read `.project/knowledge/architecture.md` for the
   `## Shared utility locations` heading.

3. **Bootstrap `inventory-utils.ts`** — Glob `.project/pipeline/scripts/inventory-utils.ts`. If
   missing, follow `.claude/skills/use-pipeline-scripts/SKILL.md`'s copy-if-missing
   protocol. Frontend prerequisite: if `.svelte-kit/tsconfig.json` is missing, run
   `pnpm --filter frontend exec svelte-kit sync` before invoking the script.

4. **Run `inventory-utils.ts`** — Bash invocation:
   `node .project/pipeline/scripts/inventory-utils.ts --tsconfig backend/tsconfig.json` (and the
   frontend tsconfig if the diff touches frontend code). Capture stable JSON output.

5. **Read all `_index.md` files** under `.project/knowledge/<type>/` so you can compare
   conventions against the diff.

6. **Compute the feature diff** — Bash:
   `git diff --name-status main...HEAD` (or the equivalent for the worktree's parent
   branch). Filter to source files. For each changed file, Read it (or relevant sections)
   to identify candidate divergences.

7. **Detect divergences.** For each diff hunk:
   - Compare inline implementations against the inventory output. If an existing utility
     exports a function that matches the inline implementation's intent, emit a
     **REUSE** finding (`directive: REUSE`) citing the existing util.
   - Compare inline implementations against the conventions in the `_index.md` rows. If a
     trigger phrase matches the feature's domain but the cited convention file was not
     followed, emit a **REUSE** finding citing the convention.
   - If the feature called an existing utility with the wrong invariants (e.g., omitted
     `organizationId`, bypassed a required guard), emit a **REUSE** finding describing
     the corrected call shape.

8. **Run disconfirmation pass.** For each candidate finding produced in step 7, consider
   a counter-argument and confirm the proposed directive is the least-invasive adequate
   response (REUSE before EXTRACT before ABSTRACT). Drop any finding that does not survive
   the counter-argument. Run this pass AFTER detection and BEFORE writing — findings
   dropped here never reach the auditor.

9. **Normalize target files to a clean starting state.** Determine the file set this
   invocation will write:

   - Always: `.project/cycles/<slug>/refactor-proposals/pattern-findings-divergence.md`.
   - When `inventory-utils.ts` was bootstrapped (copy-if-missing) this invocation: also
     `.project/pipeline/scripts/inventory-utils.ts`.

   For each path `P` in the set, run via Bash:

   ```
   if [ -f "<P>" ]; then
     if git ls-files --error-unmatch "<P>" >/dev/null 2>&1; then
       git checkout HEAD -- "<P>"
     else
       rm -f "<P>"
     fi
   fi
   ```

   - File doesn't exist → no-op (the common case for a new invocation).
   - File tracked at HEAD → `git checkout HEAD -- <path>` discards uncommitted changes;
     previously-committed content survives unchanged.
   - File untracked → `rm` removes the orphan from a crashed prior write (it was never in
     the audit trail).

   Apply the normalize step AFTER any bootstrap copy this invocation performs but BEFORE
   writing the findings file. The bootstrap path is in the file set only when the copy
   actually fired (project copy was missing); when the project copy already existed at
   invocation start, the bootstrap was a no-op and the path is not in the file set.

10. **Write findings file** — write
    `.project/cycles/<slug>/refactor-proposals/pattern-findings-divergence.md` fresh. Do NOT
    append to any other file. IDs are sequential starting from `DF-1`.

11. **Commit the artifacts.** Read `.claude/skills/commit-to-git/SKILL.md` and follow
    it to commit every path written this invocation in one path-scoped commit. Pass:

    - `Agent: pattern-analyst`
    - `Subject: refactor(<slug>): divergence findings`
    - `Path:` every path written by this invocation. The set is:
      - Always: `.project/cycles/<slug>/refactor-proposals/pattern-findings-divergence.md`.
      - When `inventory-utils.ts` was bootstrapped this invocation: also
        `.project/pipeline/scripts/inventory-utils.ts`.

    Where `<slug>` is the value of the dispatch input's `slug:` field.

    Commit nothing else. One commit per invocation. Capture the resulting short hash for
    the return. If the commit produced no change (the normalized files matched HEAD and
    the fresh writes reproduced them byte-for-byte), record `skipped`. If the commit
    fails (lock contention, hook rejection, transient error), record `failed` and surface
    it in the return — never report a success hash for a commit that did not happen.

    A failed commit must never block the return from happening; the artifacts are already
    written and the SubagentStop hook is satisfied.

12. **Return** — emit the return message (below).

## Findings File Format

```markdown
# Pattern Findings — Divergence
**Slug:** <slug>
**Run:** <ISO timestamp>

## Findings
[one block per finding, IDs DF-1, DF-2, ...]
```

REUSE finding shape:

```markdown
### Finding DF-<n>: REUSE — <existing-util-or-convention>
- directive: REUSE
- existing-target:
    kind: utility | convention
    path: <repo-relative path to existing util> | <repo-relative path to .project/knowledge/<type>/<convention>.md>
    name: <function or convention name>
- divergent-sites:
  - { file: <path>, line: <int>, snippet: <one-line> }
  - { file: <path>, line: <int>, snippet: <one-line> }
- corrected-shape: <what the call/usage should look like>
- reasoning: <one paragraph: why the existing target applies here>
```

## Return

```
Status: SUCCESS
Mode: divergence-scout
Slug: <slug>
Findings File: .project/cycles/<slug>/refactor-proposals/pattern-findings-divergence.md
Counts:
  REUSE findings: <n>
Commit: <short-hash> | skipped | failed
```

Failure / precondition violation (write did not occur):

```
Status: ESCALATE
Mode: divergence-scout
Reason: <one-line reason>
Commit: none
```

Failure / precondition violation (write occurred but commit raised an error):

```
Status: ESCALATE
Mode: divergence-scout
Reason: <one-line reason>
Commit: failed
```
