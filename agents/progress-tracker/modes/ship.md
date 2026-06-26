# Mode: `ship`

**CWD:** Worktree. **Touches:** ROADMAP only (entry's `Status` → `completed-pending-approval`). **Does NOT touch the tracking file** — the final phase was recorded by the preceding `update`; `ship` owns only the ROADMAP status transition.

## Input

```
Mode: ship
Slug: <slug>
```

## Steps

1. Resolve main-root via `git worktree list --porcelain`.
2. Register output path (Completion Gate):
   ```bash
   echo "<main-root>/.project/product/ROADMAP.md" > /tmp/.claude-agent-output-target
   ```
3. ROADMAP write (per persona's "ROADMAP write protocol"):
   - Acquire lock.
   - Read ROADMAP fresh; locate `### <slug>` block.
   - If absent → release lock; return `Status: ERROR` with `Warnings: [roadmap-entry-missing]`.
   - If `Status` already at `completed-pending-approval` → idempotent no-op; release lock; return SUCCESS with `ROADMAP-Commit: skipped`.
   - Otherwise rewrite the `Status:` bullet to `completed-pending-approval`. All other fields untouched.
   - Write back.
   - Commit per the `commit-to-git` skill (`Agent: progress-tracker`), subject `progress: <slug> ready for acceptance`, path `.project/product/ROADMAP.md`.
   - Release lock.
4. Return.

## Error conditions

- `roadmap-entry-missing` — no `### <slug>` heading found. Return `Status: ERROR`.
- `roadmap-write-failed` — write or commit failed after lock acquire. Lock released; warning surfaced.
