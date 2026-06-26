# Mode: refactor-curation

Authors and curates project-level convention files under `.project/knowledge/<type>/**`. Invoked per-phase ADDITIVELY with `cycle-phase` whenever a phase carries at least one `Concern: convention-doc` task, and invoked directly by the user to execute the project-level items in an approved knowledge-cleanup proposal. The two modes are not mutually exclusive — they handle disjoint output domains (execution-trail vs convention-domain).

This applies uniformly to feature flow, scout-and-refactor flow, and primitives flow. There is no separate "at-refactor-close" sub-mode.

## Skill Load (on-demand)

At mode entry, Read `.claude/skills/context-curation/SKILL.md`. That skill prescribes the authoring discipline for convention files: file structure, `created-during` frontmatter, `_index.md` row format with trigger phrases, Pattern A cross-reference rules, and the citation self-verification protocol. Apply its rules to every convention file you write.

Do not preload the skill via subagent `skills:` frontmatter. Read it once at mode entry.

## Inputs (from caller) — one of two

### Variant A: per-phase, orchestrator-dispatched

```
Mode: refactor-curation
Cycle: <cycle-slug>
Cycle Path: .project/cycles/<cycle>/
Phase: <N>
Plan Path: <path to implementation-plan.md>
```

The mode reads only the phase's `Concern: convention-doc` tasks. Non-convention tasks are handled by the developer in the same phase via its normal dispatch path — you do not touch them.

### Variant B: approved knowledge-cleanup proposal, user-dispatched

```
Mode: refactor-curation
Proposal Path: .project/pipeline/knowledge-cleanup-proposals/<YYYY-MM-DD>-knowledge-cleanup-proposal-run-<K>.md
```

Process only items in the proposal's `## Project-level items` section. Ignore `## User-level items` entirely — those are routed separately by the human reviewer (typically to `agent-architect`'s `promote-skill` or `update-knowledge-map` modes).

## Writes

- New convention files at `.project/knowledge/<type>/<feature-slug>/<convention>.md` or `.project/knowledge/<type>/<convention>.md`. Each new file carries `created-during: <feature-slug>` frontmatter per the context-curation skill. For retroactively migrated content authored before the pipeline existed, the value is `pre-pipeline`.
- Updates to `.project/knowledge/<type>/_index.md`:
  - New rows (one per new convention).
  - Trigger-phrase refinement (Variant B, `Promote awareness` and `Stale _index.md row` items).
  - Row insertions (Variant B, `Repair _index` items).
- Promotions: relocate a feature-local convention to top-level `<type>/` and update both indexes accordingly.
- Removals (Variant B only, `Remove` category items): delete the convention file and its `_index.md` row.
- Cross-references (Variant B, `Missing cross-reference` items): insert `## See also` lines in the cited convention files.

## Destruction Discipline

Removals are permitted ONLY when all three preconditions hold:

(a) The input is an approved knowledge-cleanup proposal (Variant B).
(b) The proposal item is a `Remove` category item.
(c) The user has approved that specific item.

Outside this triple precondition, never delete a convention file or `_index.md` row. Editing trigger phrases or merging conventions is not deletion and is permitted under the relevant category triggers.

## Boundary

This mode NEVER writes user-level files (paths under `.claude/`). The user-level items section of any approved proposal is out of scope and is processed by separate dispatches (typically `agent-architect promote-skill` or `agent-architect update-knowledge-map`).

## Workflow

1. **Register output path** — Bash: `echo "<first-file-you-will-write>" > /tmp/.claude-agent-output-target`. For Variant A, use the path of the first convention file you will create. For Variant B, use the path of the first project-level item you will write or modify.

2. **Read context-curation skill** — Read `.claude/skills/context-curation/SKILL.md`.

3. **Read relevant `_index.md` files** — for each `<type>` you will touch, Read `.project/knowledge/<type>/_index.md`. Read parent `_index.md` files when adding feature-local conventions (you will register the feature-slug subdirectory in the parent's `## Feature-specific conventions` section).

4. **Determine the full file set this invocation will touch.** The set is deterministic from the input:
   - **Variant A:** every convention file derived from the phase's `Concern: convention-doc` tasks, plus every `_index.md` whose row will be added/updated, plus parent `_index.md` files that get a `## Feature-specific conventions` row.
   - **Variant B:** every project-level item's target file in the proposal, plus every `_index.md` whose row will be added/refined/removed/relocated. For `Promote from feature-local` items, both the old (feature-local) and new (top-level) paths are in the set. For `Remove` items, the file to delete and the `_index.md` row's host file are in the set.

5. **Normalize each file in the set to a known starting state.** Handles the case where a prior dispatch wrote or moved one or more files but crashed before committing. For each path `P` in the set, run via Bash:

   ```
   if [ -f "<P>" ]; then
     if git ls-files --error-unmatch "<P>" >/dev/null 2>&1; then
       git checkout HEAD -- "<P>"
     else
       rm -f "<P>"
     fi
   fi
   ```

   - File tracked at HEAD → discards uncommitted changes; previously-committed content survives.
   - File untracked → `rm` removes the orphan.
   - File absent → no-op.

   After normalize, all paths reflect HEAD state — the relocations, deletions, and writes will reproduce cleanly on re-dispatch.

6. **Variant A:**
   - Read the implementation plan; identify the phase's tasks with `Concern: convention-doc`.
   - For each task, derive the target `<type>` (one of `backend`, `frontend`, `infrastructure`, `test`) and the convention scope (feature-local under `<feature-slug>/` or top-level under `<type>/`) from the task target path.
   - Author each convention file per the context-curation skill's discipline. Run the self-verification protocol on every code reference and backtick-enclosed symbol.
   - Add or update `_index.md` rows. Trigger phrases must echo plan-task verb-noun phrasing per the skill's `_index.md` row format rules.
   - When introducing a new feature-local convention subdirectory, add the corresponding row to the parent `_index.md`'s `## Feature-specific conventions` section.

7. **Variant B:**
   - Read the proposal. Process only the `## Project-level items` section.
   - For each item, apply the action prescribed by its category:
     - `Promote awareness` / `Stale _index.md row` → refine the trigger-phrase in `_index.md`.
     - `Promote from feature-local` → relocate the file to top-level; update both indexes.
     - `Remove` → verify destruction discipline preconditions hold; delete file + remove row.
     - `Repair _index` → insert the row.
     - `Knowledge-map gap (project-level)` → add the `_index.md` row.
     - `Overlap merge` → merge contents (per the item's recommendation) or add cross-references.
     - `Missing cross-reference` → insert `## See also` lines in the cited convention files.
   - For paired `Post-promotion redundancy` items, execute the project-level `Remove` portion only. The user-level frontmatter cleanup is out of scope (it appears in the proposal's user-level section, routed separately).

8. **Verify writes** — Glob the `.project/knowledge/<type>/` tree to confirm every new file is in its expected location and every `_index.md` row points to an extant file. The context-curation skill's self-verification protocol covers in-file claims; this step covers cross-file consistency.

9. **Commit the curation artifacts.** Read `.claude/skills/commit-to-git/SKILL.md` and follow it to commit every path touched this invocation in one path-scoped commit. Pass:

   - `Agent: state-manager`
   - `Subject:`
     - **Variant A:** `state(<slug>): phase <N> curation`, where `<slug>` is the basename of the feature directory from the input's `Cycle Path`, and `<N>` is the phase number.
     - **Variant B:** `state: curation proposal <date>`, where `<date>` is the `YYYY-MM-DD` segment from the proposal filename. The subject drops the `(<slug>)` segment because Variant B is feature-wide and not scoped to a single feature.
   - `Path:` every path written, modified, relocated, or deleted by this invocation. For relocations (Variant B `Promote from feature-local`), include BOTH the old and new paths so git records the rename atomically. For deletions (Variant B `Remove`), include the deleted path so the deletion is recorded.

   Commit nothing else. One commit per invocation. Capture the resulting short hash for the return. If the commit produced no change (the normalized files matched HEAD and the writes reproduced them byte-for-byte), record `skipped`. If the commit fails (lock contention, hook rejection, transient error), record `failed`.

## Output

**Variant A:**

```
Status: SUCCESS
Mode: refactor-curation
Variant: per-phase
Conventions Written: <count>
Index Updates: <count>
Files:
  - <path>
  - <path>
  ...
Commit: <short-hash> | skipped | failed
```

**Variant B:**

```
Status: SUCCESS
Mode: refactor-curation
Variant: proposal
Proposal: <proposal path>
Items Processed: <count>
Files:
  - <path> — <action>
  - <path> — <action>
  ...
Commit: <short-hash> | skipped | failed
```

**Failure / precondition violation:**

```
Status: ESCALATE
Mode: refactor-curation
Reason: <one-line reason>
Commit: none
```

`Commit:` semantics are documented in `state-manager.md` Output Format Conventions.
