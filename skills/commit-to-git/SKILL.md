---
name: commit-to-git
description: Single source of truth for how pipeline agents and skills commit to git. Defines the path-scoped commit form (never a naive `git commit -m`), the explicit `git add -- <path>` staging step that the form presumes, the `Agent:` attribution trailer, the main-side vs worktree-side command variants, and the merge/amend edge cases. TRIGGER when about to run `git add` / `git commit` to persist your own artifacts. Subagents Read this SKILL.md directly at their commit step; chat-driving skills and the main agent invoke it via the Skill tool. Loaded on-demand — never preloaded via `skills:` frontmatter.
domain: dev-tooling
user-invocable: false
---

# Commit to Git

How every pipeline agent and skill records a git commit. You supply three inputs; this skill defines the *form*:

- **`Agent`** — your own role name (the committer's `name`, e.g. `plan-architect`). Recorded as a trailer so history answers "which pipeline role produced this commit."
- **`Subject`** — the commit subject line. You own your message convention; this skill never dictates wording.
- **`Path(s)`** — the exact artifact path(s) you just wrote.

## Rules

1. **Path-scoped, always.** Never a naive `git commit -m "<subject>"`. Always end the command with `-- <path> [<path> ...]` naming only the files you wrote. The naive form sweeps unrelated staged work out of the index into your commit.

2. **Stage your files explicitly.** Run `git add -- <path> [<path> ...]` before the commit — `git commit -- <path>` only persists paths already in the index, so a freshly created (untracked) file falls through silently and the commit appears successful while writing nothing.
   - Safe for already-tracked modified files too: path-scoped `git add` stages only what you name, so it never sweeps in unrelated work.
   - Use the same `-C <root>` (or no `-C`) for both `add` and `commit` — they must target the same repo.

3. **Attribution trailer.** Append `--trailer "Agent: <name>"` after all `-m` flags and before the `--` path separator:
   ```
   git -C <root> commit -m "<subject>" --trailer "Agent: <name>" -- <path>
   ```
   Requires git ≥ 2.32. If `--trailer` is ever unavailable, a final `-m "Agent: <name>"` before `--` produces the same trailer block — but prefer `--trailer`.

4. **Dual-context command form** — pick `<root>` from where you are running. Each variant is a two-step sequence (stage, then commit):
   - **Main-side** (CWD is the main repo: design-time, no active worktree, or an artifact whose canonical home is main): use `-C <main-root>` on both commands.
     ```
     git -C <main-root> add -- <path>
     git -C <main-root> commit -m "<subject>" --trailer "Agent: <name>" -- <path>
     ```
   - **Worktree-side** (CWD is under `.worktrees/<leaf>/`, e.g. dispatched by the orchestrator): run from the worktree CWD with no `-C`.
     ```
     git add -- <path>
     git commit -m "<subject>" --trailer "Agent: <name>" -- <path>
     ```
     Do **not** add `-C <main-root>` here — it would mis-target main.
   - **Context signal:** your working directory / the dispatch's `Working Directory:` footer. Artifacts that live inside the active worktree (plans, audit reports, code, summaries) commit worktree-side. Artifacts whose canonical home is main (ROADMAP, tracking files, milestone archives) commit main-side with `git -C <main-root>` even when CWD is a worktree.

5. **Merge commits** (e.g. `accept-feature`): `git commit --no-edit --trailer "Agent: <name>"`. `--trailer` composes with `--no-edit`. No `git add` step here — the merge already populated the index.

6. **Amend that reuses the message** (e.g. `git commit --amend --no-edit`): do **not** re-add the trailer — it is already on the commit being amended, and re-adding risks a duplicate line. Only commits that author a fresh message carry the trailer. If the amend folds in new files, stage them first with `git add -- <path>`.

7. **Commit only your own artifacts.** Never stage or commit files you didn't write. The ROADMAP and everything under `.project/product/` have a single dedicated owner — a commit (or a stray `git add`) from anywhere else touching them is a bug.
