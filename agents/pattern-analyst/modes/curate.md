# Mode: curate

Resolves `MODIFY-AS` verdicts in the per-cycle audit by editing findings + audit files in
place (after archiving each to `*-original.md`), then runs `curate-approved.ts` to emit
the per-cycle `pattern-approved.md`. This is the only mode permitted to mutate audit
verdicts after the auditor has written them, and the only mode permitted to revise
findings files post-scout.

## Inputs

```
Mode: curate
slug: <slug>
```

- All `pattern-findings-*.md` files inside `.project/cycles/<slug>/refactor-proposals/`.
  - Scout-and-refactor flow: `pattern-findings-convergence.md` +
    `pattern-findings-divergence.md`.
  - Primitives flow: `pattern-findings.md`.
- The single `pattern-audit.md` in the same directory (produced by
  `pattern-analyst-auditor`).

## Bootstrap Responsibility

- Sole bootstrapper and sole runner of `curate-approved.ts` (per
  `.claude/skills/use-pipeline-scripts/SKILL.md`). On first use, follow the
  copy-if-missing protocol. The script's strict input contract requires the audit to
  contain only `ACCEPT` and `REJECT` at invocation time — `MODIFY-AS` must be resolved
  beforehand by this mode.

## Verdict Doctrine

- The auditor's verdicts are: `ACCEPT`, `REJECT`, `MODIFY-AS:<corrected-shape>`.
- This mode is the ONLY actor permitted to mutate audit verdicts after the auditor has
  written them.
- `MODIFY-AS:<corrected-shape>` means "the proposal is roughly right, but use this
  shape." This mode applies the correction and converts the verdict to `ACCEPT`.
  `MODIFY-AS` ALWAYS becomes `ACCEPT`, NEVER `REJECT`.
- `REJECT` is final. This mode NEVER alters it. Findings the auditor truly wants
  discarded must be `REJECT` from the start.
- After this mode finishes its edits, the audit file contains only `ACCEPT` and
  `REJECT` verdicts. Any remaining `MODIFY-AS` is a defect the script surfaces as
  `UNRESOLVED_MODIFY_AS`.

## Workflow

1. **Register output path** — Bash:
   `echo ".project/cycles/<slug>/refactor-proposals/pattern-approved.md" > /tmp/.claude-agent-output-target`.

2. **Discover findings files** — Glob
   `.project/cycles/<slug>/refactor-proposals/pattern-findings-*.md`. The slug subdirectory is
   fully owned by this cycle, so the glob is bounded and unambiguous. Build a list of
   discovered paths.

3. **Read the audit** — Read `.project/cycles/<slug>/refactor-proposals/pattern-audit.md`. Parse
   per-finding verdicts.

4. **Resolve `MODIFY-AS` verdicts** — if any `MODIFY-AS` verdicts exist:
   1. For EACH findings file in the discovered list: copy it to `<stem>-original.md` if
      that archive does not already exist. Skip archives that exist (idempotent).
   2. Copy the audit file to `pattern-audit-original.md` if that archive does not
      already exist.
   3. For each `MODIFY-AS:<corrected-shape>` verdict:
      - The audit's `Origin:` line names the source findings file. Locate the finding by
        ID in that file.
      - Edit the findings file in place: rewrite the finding's shape to match the
        corrected shape.
      - Edit the audit file in place: change the verdict from `MODIFY-AS:<...>` to
        `ACCEPT`. Preserve the `Origin:` and `Reasoning:` lines as-is.

5. **Normalize `pattern-approved.md` to a clean starting state** — handles the case
   where a prior dispatch wrote the approved file but crashed before committing. For
   `.project/cycles/<slug>/refactor-proposals/pattern-approved.md`, run via Bash:

   ```
   if [ -f ".project/cycles/<slug>/refactor-proposals/pattern-approved.md" ]; then
     if git ls-files --error-unmatch ".project/cycles/<slug>/refactor-proposals/pattern-approved.md" >/dev/null 2>&1; then
       git checkout HEAD -- ".project/cycles/<slug>/refactor-proposals/pattern-approved.md"
     else
       rm -f ".project/cycles/<slug>/refactor-proposals/pattern-approved.md"
     fi
   fi
   ```

   Do NOT normalize the findings files, the audit, or any `*-original.md` archive — the
   in-place MODIFY-AS edits in step 4 are content-idempotent (re-applying the same
   correction is a no-op once the verdict has been changed to `ACCEPT`), and the archive
   copies in step 4.1/4.2 are guarded by their own "skip if exists" rule.

   If `curate-approved.ts` was bootstrapped (copy-if-missing) earlier in this invocation
   — or will be bootstrapped in step 6 below — its target path
   `.project/pipeline/scripts/curate-approved.ts` is also part of the commit set; normalize it
   here with the same recipe BEFORE the bootstrap runs in step 6 (so a prior dispatch's
   uncommitted copy is discarded before this dispatch re-copies). In practice the script
   is typically bootstrapped once across many cycles, so this is a no-op on most runs.

6. **Run `curate-approved.ts`** — Bash:
   ```
   node .project/pipeline/scripts/curate-approved.ts \
     --findings <comma-separated discovered findings paths, no spaces> \
     --audit .project/cycles/<slug>/refactor-proposals/pattern-audit.md \
     --out .project/cycles/<slug>/refactor-proposals/pattern-approved.md
   ```
   Bootstrap the script per `.claude/skills/use-pipeline-scripts/SKILL.md` if the
   project copy is missing.

7. **Handle script errors:**
   - `UNRESOLVED_MODIFY_AS` — Read stderr for offending finding IDs. For each, repeat
     step 4.3 (edit the correct findings file + audit verdict). Re-run the script.
     **Maximum 1 retry.** If the second run still returns `UNRESOLVED_MODIFY_AS`,
     escalate with the still-unresolved IDs and stop.
   - `FINDING_ID_COLLISION` — escalate to the caller. Finding IDs MUST be globally
     unique across scouts; collision is a `pattern-analyst` defect (the prefixing
     convention should make collisions impossible by construction), not a curate
     concern.
   - `FINDINGS_AUDIT_MISMATCH` — escalate. The audit references a finding ID that
     doesn't exist (or a finding has no audit verdict). Either the audit or findings
     file is malformed.
   - `FINDINGS_NOT_FOUND` / `AUDIT_NOT_FOUND` — escalate. The dispatch landed in the
     wrong worktree or the cycle subdirectory is missing files.

8. **Verify `approved.md`** — Read the produced
   `.project/cycles/<slug>/refactor-proposals/pattern-approved.md`. Confirm it is well-formed
   and check for the `NO_PROPOSALS_APPROVED` marker.

9. **Commit the artifacts.** Read `.claude/skills/commit-to-git/SKILL.md` and follow
   it to commit every path written this invocation in one path-scoped commit. Pass:

   - `Agent: pattern-analyst`
   - `Subject: refactor(<slug>): curate approved`
   - `Path:` every path written by this invocation. The set is:
     - Always: `.project/cycles/<slug>/refactor-proposals/pattern-approved.md`.
     - When MODIFY-AS verdicts were resolved this invocation:
       - Every findings file edited in step 4.3 (one entry per file actually mutated).
       - `.project/cycles/<slug>/refactor-proposals/pattern-audit.md` (the in-place verdict
         changes).
       - The `*-original.md` archive for every findings file that was edited
         (e.g. `pattern-findings-convergence-original.md` if convergence findings were
         mutated).
       - `.project/cycles/<slug>/refactor-proposals/pattern-audit-original.md` (the audit
         archive).
     - When `curate-approved.ts` was bootstrapped this invocation: also
       `.project/pipeline/scripts/curate-approved.ts`.

   Where `<slug>` is the value of the dispatch input's `slug:` field.

   Commit nothing else. One commit per invocation. Capture the resulting short hash for
   the return. If the commit produced no change (all paths matched HEAD byte-for-byte),
   record `skipped`. If the commit fails (lock contention, hook rejection, transient
   error), record `failed` and surface it in the return — never report a success hash for
   a commit that did not happen.

   A failed commit must never block the return from happening; the artifacts are already
   written and the SubagentStop hook is satisfied.

10. **Return** — emit the appropriate return message (below).

## Output

`.project/cycles/<slug>/refactor-proposals/pattern-approved.md` — produced by
`curate-approved.ts`. Contains only the `ACCEPT` findings preserved verbatim from their
source findings files, each preceded by an `<!-- origin: <findings-file-path> -->`
comment line for traceability.

When zero `ACCEPT` verdicts remain, the script still produces the file with the
`NO_PROPOSALS_APPROVED` marker. The orchestrator interprets that marker to skip
plan-architect dispatch and ship the cycle as no-op.

## Return

Successful curation with approved proposals:

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

Successful curation with no approvals:

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

Failure / precondition violation (write did not occur):

```
Status: ESCALATE
Mode: curate
Reason: <one-line reason, e.g. UNRESOLVED_MODIFY_AS after retry: <id list>>
Commit: none
```

Failure / precondition violation (write occurred but commit raised an error):

```
Status: ESCALATE
Mode: curate
Reason: <one-line reason>
Commit: failed
```
