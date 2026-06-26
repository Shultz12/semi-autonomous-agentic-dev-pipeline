# Commit to Git Guide

## What It Does

Defines the single, authoritative form for every git commit made by a pipeline agent or skill — so the commit convention lives in one place and changes in one edit.

**Key Points:**
- Mandates the path-scoped commit form (`commit … -- <path>`), never a naive `git commit -m`, so unrelated staged work is never swept into a commit
- Requires an explicit `git add -- <path>` before `git commit -- <path>` — the path-scoped commit form does not auto-stage untracked files, so a freshly created file would otherwise fall through silently
- Adds an `Agent: <name>` git trailer to every fresh-message commit, recording which pipeline role produced it
- Specifies the main-side (`-C <main-root>`) vs worktree-side (no `-C`) command variants and how to tell which applies
- Covers the merge-commit and amend edge cases (when the trailer is and isn't re-added)

## When It's Used

Loaded on demand — never preloaded via any `skills:` frontmatter. There's no slash command; it's not user-invocable.

Two consumer types pull from it:
- **Subagents** (invoked via the Agent tool, no Skill tool): `plan-architect`, `plan-auditor`, `progress-tracker`, `developer`, `milestone-archivist`, `quality-analyst`. Each `Read`s the `SKILL.md` at its commit step (progressive disclosure).
- **Chat-driving skills** (have the Skill tool): `orchestrator`, `product-architect`, `spec-architect`, `design-architect`, `accept-feature`. Each invokes the skill via the Skill tool when about to commit; the skill's description is what makes that discoverable.

Either way the caller supplies `Agent: <own-name>`, its own subject line, and the path(s) it wrote.

## The Rules

| # | Rule | Why |
|---|------|-----|
| 1 | Path-scoped, always (`-- <path>`) | A naive `git commit -m` sweeps unrelated staged work out of the index into your commit |
| 2 | Stage your files explicitly (`git add -- <path>`) before the commit | `git commit -- <path>` only persists indexed paths; an untracked file falls through silently and the commit succeeds while writing nothing |
| 3 | Append `--trailer "Agent: <name>"` | Records which pipeline role produced the commit; requires git ≥ 2.32 (`-m "Agent: <name>"` is the equivalent fallback) |
| 4 | Main-side uses `-C <main-root>`; worktree-side uses no `-C` | Running worktree-side with `-C <main-root>` would mis-target main |
| 5 | Merge commits: `git commit --no-edit --trailer "Agent: <name>"` | `--trailer` composes with `--no-edit`; merge already populated the index, so no separate `git add` |
| 6 | `--amend --no-edit`: do **not** re-add the trailer | It's already on the commit being amended; re-adding risks a duplicate line |
| 7 | Commit only your own artifacts | The ROADMAP and `.project/product/` have a single owner; a commit (or stray `git add`) elsewhere touching them is a bug |

## Limitations

- Behavioral guidance, not enforcement — it cannot prevent a caller whose own instructions conflict from committing differently
- Defines commit *form* only; the subject-line wording stays with each caller's own message convention
- Covers local commits, not pushes or remote operations

## Related Files

| File | Purpose |
|------|---------|
| `.claude/skills/commit-to-git/SKILL.md` | Skill definition (the rules themselves) |
| `.claude/skills/bash-usage/SKILL.md` | Peer discipline skill — Bash usage rules |
| `.claude/skills/create-folder/SKILL.md` | Peer discipline skill — directory creation rules |
