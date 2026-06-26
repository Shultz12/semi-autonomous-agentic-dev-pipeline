# Mode: `close`

**CWD:** Main. **Touches:** ROADMAP (final transition for the entry; conditional milestone status) and tracking file (delete).

## Input

```
Mode: close
Slug: <slug>
Final-Status: completed | abandoned
Worktree-Type: feature | refactor | primitives | bugfix
Scout-Result: empty | approved | n/a       (n/a when Worktree-Type=feature, bugfix, or primitives;
                                            empty or approved when Worktree-Type=refactor)
Parent-Feature: <slug> | n/a               (required when Worktree-Type=refactor; n/a otherwise)
```

## Behavior — `Final-Status: completed`

| `Worktree-Type` | `Scout-Result` | Behavior |
|---|---|---|
| feature    | `n/a`     | On the `### <slug>` block: set `Status: completed`, set `Completed: <YYYY-MM-DD>`, remove `Worktree:` line, set `Scout-status: pending`. Delete tracking file. |
| refactor   | `approved`| Locate the refactor entry `### <slug>` (the slug is the refactor slug — no derivation); set its `Status: completed`, `Completed: <YYYY-MM-DD>`, remove `Worktree:` and `Stage:` lines. Locate parent feature's `### <parent-feature>` block; set its `Scout-status: completed`. Delete the refactor's tracking file. |
| refactor   | `empty`   | Locate the refactor entry `### <slug>`; remove the entire heading block (including all bullet fields). Locate parent feature's `### <parent-feature>` block; set its `Scout-status: empty-result`. Delete the refactor's tracking file. |
| primitives | `n/a`     | Locate the primitives entry `### <slug>`; set `Status: completed`, `Completed: <YYYY-MM-DD>`, remove `Worktree:` and `Stage:` lines; leave `Scout-status: n/a`. Delete tracking file. (A primitives cycle closes identically whether or not it approved proposals — the entry is kept as a permanent "primitives ran" record. The approved-vs-empty outcome drives no close behavior, so `Scout-Result` is `n/a`.) |
| bugfix     | `n/a`     | On the `### <slug>` block: set `Status: completed`, set `Completed: <YYYY-MM-DD>`, remove `Worktree:` line. Leave `Scout-status: n/a` unchanged — a bug fix seeds no scout cycle. Delete tracking file. |

## Behavior — `Final-Status: abandoned`

| `Worktree-Type` | Behavior |
|---|---|
| feature    | On the `### <slug>` block: revert to `Status: planned`; remove `Worktree:` and `Started:` lines; leave `Scout-status: n/a`. Delete tracking file. |
| refactor   | Locate the refactor entry `### <slug>` (the slug is the refactor slug — no derivation; the entry always exists post-`start`); remove the entire heading block (including all bullet fields). Locate parent feature's `### <parent-feature>` block; restore `Scout-status: pending` (re-queues post-merge investigation). Delete the refactor's tracking file. |
| primitives | Locate the primitives entry `### <slug>` (it always exists post-`start`); remove the entire heading block (including all bullet fields). Delete tracking file. |
| bugfix     | Locate the bugfix entry `### <slug>`; remove the entire heading block (including all bullet fields). A bug fix has no `planned` backlog state to revert to, so removal is the only correct teardown. Delete tracking file. |

## Steps

1. Resolve main-root (`pwd`).
2. Register output path (Completion Gate):
   ```bash
   echo "<main-root>/.project/product/ROADMAP.md" > /tmp/.claude-agent-output-target
   ```
3. **ROADMAP write** (per persona's "ROADMAP write protocol") — for every close row:
   - Acquire lock.
   - Read ROADMAP fresh.
   - Apply the matrix-row behavior above (mutate entry fields; possibly remove an entire heading block; possibly update parent's `Scout-status`).
   - Write back.
   - Commit per the `commit-to-git` skill (`Agent: progress-tracker`), path `.project/product/ROADMAP.md`, with one of these subjects:
     - `progress: <slug> completed` (used for `feature`, `refactor / approved`, `primitives`, and `bugfix` completed closes — the subject is action-named, not type-named)
     - `progress: <slug> abandoned` (used for `feature` abandon, which reverts to `planned` rather than removing)
     - `progress: refactor cycle <slug> empty-result` (on `refactor / empty` close)
     - `progress: remove refactor entry <slug>` (on `refactor` abandon)
     - `progress: remove bugfix entry <slug>` (on `bugfix` abandon — the "remove …" form mirrors `refactor` abandon, because the bugfix abandon path deletes the entire heading block rather than reverting it)
   - Release lock.
4. **Delete tracking file** (for every matrix row whose Behavior says "Delete tracking file"):
   ```bash
   rm -f "<main-root>/.project/product/cycles-in-progress/<slug>.md"
   ```
   Then commit the deletion per the `commit-to-git` skill (`Agent: progress-tracker`), subject `progress: remove tracking file for <slug>`, path `.project/product/cycles-in-progress/<slug>.md`. If the tracking file is already absent, skip the rm + commit but still run the ROADMAP write.

5. **Milestone-completion check** — only when `Final-Status: completed`. Skipped entirely for `abandoned`.
   1. Acquire ROADMAP lock again.
   2. Read ROADMAP fresh (post-step-3, so the just-flipped entry reflects `Status: completed`).
   3. Locate the `## Milestone: <version> — <description>` heading whose section contains the just-closed `### <slug>` block. Capture `<version>`.
      - If `<slug>` was a refactor slug whose entry was removed (`Worktree-Type=refactor, Scout-Result=empty`), use the parent feature's milestone instead.
   4. Read the milestone's own `**Status:**` line. If already `completed`, set `MilestoneCompleted: <version>` and skip the rest of step 5 (idempotent — re-running close on a milestone-final entry must not re-flip).
   5. Walk every `### <slug>` block inside that milestone's section (between the matched `## Milestone:` heading and the next `## ` heading). If every block's `Status:` is `completed`, the milestone is now done; otherwise set `MilestoneCompleted: false` and skip steps 5.6 and 5.7.
   6. Rewrite the milestone's `**Status:**` line to `completed`. Write back.
   7. Commit per the `commit-to-git` skill (`Agent: progress-tracker`), subject `progress: milestone <version> completed`, path `.project/product/ROADMAP.md`.
   8. Set `MilestoneCompleted: <version>`.
   9. Release lock.

6. Return.

## Idempotency

- If the tracking file is already absent, skip the rm + commit but still run the ROADMAP write.
- If the ROADMAP entry is already in the target state for `Final-Status: completed` (already at `Status: completed`), the write is a no-op; commit emits `skipped`. `close` still runs the milestone check.
- The milestone-completion check is itself idempotent: a re-run with the milestone already at `Status: completed` returns `MilestoneCompleted: <version>` without re-issuing the milestone write.

## Error conditions

- `roadmap-entry-missing` — the slug's `### <slug>` block isn't in ROADMAP (and isn't expected to be removed). Return `Status: ERROR`.
- `milestone-missing` — the entry isn't inside any `## Milestone:` section, so the milestone-completion check cannot proceed. Return `Status: ERROR`.
- `roadmap-write-failed` / `commit-failed` — surface in `Warnings`.
