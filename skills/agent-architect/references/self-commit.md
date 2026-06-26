# Self-Commit Instruction

When an agent or skill writes files into the **project repository**, it must persist them itself — uncommitted work left in the tree becomes the next stage's (or the user's) problem to untangle. Build the commit step into the artifact during create/update; do not leave committing to the caller.

## When it applies

Decide by **where the artifact writes**, by reading its workflow:

- **Applies** — the artifact writes files under the project (`.project/`, project source, project-level `.claude/`, any path inside the repo working tree). It commits the files it wrote.
- **Does not apply** — the artifact writes only user-level files under `.claude/` (reviews, agents, skills, personal docs), or produces no files at all (returns findings to its caller, prints output). User-level files live outside any project repo, so there is nothing to commit.

An artifact that writes both commits only the project-level files. When in doubt, inspect every Write/Edit target: a project-relative or `.project/`-rooted path means the step applies; a `.claude/`-rooted path does not.

## What to embed

The commit step references the `commit-to-git` skill through **progressive disclosure** — never preloaded via `skills:` frontmatter. Frontmatter preloading burns context on every run and a passively-loaded skill can be ignored; placing the reference at the artifact's final workflow step guarantees the agent reaches it and reads it exactly when it commits.

**For a sub-agent** — add a final workflow step in the agent's own voice:

> ## Step N: Commit your work
> After writing your artifacts, commit the files you created under the project. Read `.claude/skills/commit-to-git/SKILL.md` and follow it, passing `Agent: <agent-name>` and the exact path(s) you wrote.

**For a skill** — add a closing step:

> When you finish writing your artifacts, commit the project files you created: invoke the `commit-to-git` skill (Skill tool) and follow it, passing `Agent: <skill-name>` and the path(s) you wrote.

Use the artifact's own `name` literally. Do not embed the path-scoped form, the `Agent:` trailer mechanics, or the main-vs-worktree variants — those belong to `commit-to-git`, and restating them creates a second source of truth that will drift.

## Return-message `Commit:` field

Every committing agent reports a `Commit:` field on its return message per convention 0.3.7. The dispatcher uses presence/absence of `Commit:` as its interrupted-commit-recovery signal — re-dispatching the same invocation when the field is absent — so any agent that commits must also surface the result. Embed the field in every return template the artifact carries: workflow return-status blocks, per-mode return templates, and the corresponding section of the interface contract.

Documented values:

- `<short-hash>` — commit recorded; the short hash returned by `commit-to-git`.
- `skipped` — write produced no diff against HEAD; no commit was forced (convention 0.3.7).
- `none` — invocation produced no artifact (e.g., short-circuit before any Write).
- `failed` — write succeeded but the commit attempt failed; the agent surfaces the failure rather than reporting a fake hash.

Atomicity matters more than convenience: never report `Commit: <hash>` for a commit that did not actually happen. If the commit step errors, the return must carry `Commit: failed` so the dispatcher can route to recovery instead of trusting a phantom hash.

## Pipeline participants

If the artifact also participates in the feature pipeline (writes under `.project/cycles/*` or `.project/product/*`, runs inside `.worktrees/<cycle>/`, or commits on behalf of a feature), its commit behavior carries extra rules — main-vs-worktree context and the single ROADMAP owner. Those live in [pipeline-role-templates.md](pipeline-role-templates.md) (Role 1 — Committer). Embed that role's content for pipeline participants; it supersedes the baseline step above and references the same `commit-to-git` skill, so state the commit reference once, not twice.

## Telling the user

You add this step on your own initiative. State plainly in the summary which way it went and why — e.g. "Added a final commit step: this agent writes plans under `.project/`, so it commits them via `commit-to-git`," or "No commit step: this agent only writes a review file under `.claude/reviews/`, outside any project repo." This keeps the decision visible and overridable.
