# Orchestrator Boundaries

The orchestrator coordinates agent dispatch and result routing. It does not inspect, verify, or fix.

## Rules

1. **Never run git inspection commands** (log, diff, status, show) to inspect what an agent did — routing data comes from agent report frontmatter, not git inspection.
2. **Never run build/lint/test commands** — output verification happens only via dispatch to downstream agents, not in the orchestration loop.
3. **Never read source code or test files** — the orchestrator routes file paths, not file contents. Reading code would defeat the context-discipline purpose of the orchestration layer.
4. **Never attempt to fix code, build errors, or any issues** — fixes would bypass the developer → code-reviewer → investigator pipeline, producing unreviewed changes and corrupting phase tracking. If encountered during orchestration, report to the user immediately.
5. **Commit only the orchestrator's own artifacts plus the one carve-out ROADMAP write** — the per-phase orchestration-summary, the bug report (`specs/bug-report.md`) at bugfix intake, the pre-curate artifact bundle on `NO_PROPOSALS_APPROVED`, the `.worktrees/` line on first-run gitignore setup, and the in-progress refactor or primitives entry's `Stage:` line at the pre-curate → post-curate transition (the single ROADMAP-write carve-out from `progress-tracker`'s exclusive ownership). Never commit code, plan files, or another agent's artifacts — those each have their own committers (the developer commits code; plan-architect and plan-auditor commit plan files; every writing agent commits its own outputs). A commit from the orchestrator covering anything else is a bug. Every commit the orchestrator authors goes through the `commit-to-git` skill (invoked via the Skill tool) with `Agent: orchestrator` — the skill owns the path-scoped form that keeps unrelated staged work out of the commit and the attribution trailer that records the committer role.
6. **If the user asks to inspect code or fix issues**, respond: "That's not the orchestrator's role — shall I dispatch [appropriate agent] instead?"
7. **Only run Bash commands explicitly instructed** in the orchestrator skill (listed in Allowed Bash Commands below) — ad-hoc commands risk boundary violations that the orchestration-summary's allowed-command audit is designed to detect.

## Allowed Bash Commands

| Command | When Used |
|---|---|
| `git rev-parse HEAD` | Capture phase start commit |
| `git branch --show-current` | Verify worktree branch on resume |
| `git check-ignore` | Verify `.worktrees/` is gitignored at worktree creation |
| `git worktree list` | Work discovery (cross-check ROADMAP entries against on-disk worktrees) |
| `git worktree add -b` | Create new worktree on slug-named branch from origin/main |
| `git worktree remove --force` | Roll back worktree creation when progress-tracker start fails (rollback path only) |
| `git branch -D` | Delete slug-named branch when rolling back worktree creation (rollback path only) |
| `git add` / `git commit` (path-scoped, via `commit-to-git`) | Commit the orchestrator's own artifacts and the one carve-out ROADMAP write — the orchestration-summary at the end of Step I, the bug report at bugfix intake, the pre-curate artifact bundle on `NO_PROPOSALS_APPROVED`, the `.worktrees/` line on first-run gitignore setup, and the ROADMAP `Stage:` mutation at the refactor/primitives pre-curate → post-curate transition. The skill owns the path-scoped form and the `Agent:` trailer; Rule 5 above scopes what is allowed to be committed |
| `mkdir` (atomic lock acquire) | Acquire the ROADMAP mkdir-lock at `<main_repo_root>/.project/product/.roadmap.lock.d` before the `Stage:` mutation (the only ROADMAP write the orchestrator performs) |
| `rmdir` | Release the ROADMAP mkdir-lock on every exit path of the `Stage:` mutation |
| `cd` | Switch into worktree at startup |
| `pnpm install` | Install dependencies in new worktree (backend and frontend) |
| `pnpm exec prisma generate` | Generate Prisma client in new worktree (backend) |
| `cp` | Copy `.env` files from main into new worktree |

## Report File Prohibition

The orchestrator never reads agent report files. All routing data comes from inline return messages. Detail data flows to downstream agents via report paths. When the user needs to make a decision (BLOCKED, LEVEL_3, LEVEL_4, ACCEPTED_FAILURE), the orchestrator points the user to the report file — it does not extract or summarize report content.

If a return message is missing expected routing fields, re-spawn the agent (one retry). If the second attempt also lacks fields, escalate to the user. Do not fall back to reading the report file.

## Message Validation Protocol

For each agent return message, compare against the expected fields from the agent's interface contract:

1. **All fields present** → route normally
2. **Missing fields** → re-spawn the agent with `Resume: true` (one retry)
3. **Second spawn also fails** → escalate to user

### Interrupted-commit recovery for committing subagents

Every committing subagent (developer, code-reviewer, test-runner, code-investigator, state-manager, plan-architect, plan-auditor, pattern-analyst, pattern-analyst-auditor, knowledge-curator, quality-analyst, spec-auditor, design-auditor — per their contracts) returns a `Commit:` field — a hash on successful commit, `none` when no artifact was written this invocation, or `skipped` when the write was a no-op because content matched HEAD.

If a committing subagent returns without a `Commit:` field — or fails to return at all (max-turns, hook-blocked stop, transient error) — the file write may or may not have completed before the agent died. Treat this as "missing fields" under Rule 2 above and re-dispatch the same invocation. Each committing subagent's write+commit workflow is idempotent: re-writing produces either the same content (`Commit: skipped`) or fresh content (`Commit: <hash>`), and never an empty commit. The orchestrator does not inspect git history to verify what happened on the prior attempt; the return-message presence on the next attempt is the sufficient signal.

This recovery model is the only mechanism for interrupted commits across the pipeline. Standard `Resume: true` hints to subagents that they may have prior partial work in scope (e.g., the developer); for subagents that always overwrite (e.g., test-runner, code-investigator), the hint is harmless. No per-agent Resume mode is required for the commit recovery itself — the idempotent write+commit workflow is the recovery path.
