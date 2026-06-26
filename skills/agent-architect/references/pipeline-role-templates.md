# Pipeline Agent Role Templates

Condensed catalog for authoring or updating agents and skills that participate in the feature pipeline (spec → design → plan → orchestrator → developer → review → test → accept/abandon). Each role carries a fixed set of rule content that must appear in the agent's own prose, in its own voice. Never cite external rule labels or shared rulebook files — the rule content stands alone in every agent.

An agent may embody more than one role (for example, a tool that runs in both a user-driven design-time branch and an orchestrator-driven worktree branch). Embed every applicable rule set, clearly sectioned under named headings the reader will recognize (e.g., "User-driven branch" vs "Orchestrator-driven branch").

## Role-fit questions

Answer in order. A yes means the role applies. Roles are not exclusive.

1. **Does the agent record git commits (on main, or on its worktree branch)?** → Committer.
2. **Does the agent run inside `.worktrees/<cycle>/` and write under `.project/`?** → Worktree-side writer.
3. **Does the agent write specs, design, or plans on main before a worktree is cut?** → Design-time writer.

## Role 1 — Committer (main-side or worktree-side)

**Fits:** any agent/skill that records git commits — on main (artifacts whose canonical home is main) or on a worktree branch (artifacts that live inside the active worktree). Main-side calibration examples: `progress-tracker`, `product-architect`, `milestone-archivist`, `spec-architect`, `design-architect`. Worktree-side calibration examples: `developer`, `plan-auditor`, orchestrator-driven `plan-architect`.

**Required rule content (paraphrase in the host's voice):**

- Committers obtain their commit form from the `commit-to-git` skill — subagents Read `.claude/skills/commit-to-git/SKILL.md` at the commit step (progressive disclosure); chat-driving skills invoke it via the Skill tool — and pass `Agent: <name>`. The skill owns the path-scoped form, the `Agent:` attribution trailer, and the main-side (`git -C <main-root>`) vs worktree-side (no `-C`) variants; the host does not restate them. A naive `git commit -m <msg>` is forbidden — it sweeps in unrelated staged work from the index.
- A single dedicated stage owns `ROADMAP.md` — its creation and every transition — and writes it directly under a mkdir-lock protocol. Every other agent never touches `ROADMAP.md` on its own; a direct write would race the single-owner model the pipeline relies on for idempotency and merge safety. Name that owner (`progress-tracker`) **only if this agent actually dispatches it** (e.g., `product-architect`, which dispatches `init`). An agent that neither writes the ROADMAP nor dispatches its owner states only that it never writes the ROADMAP, and names no owner — a subagent cannot invoke another subagent, so the reference would be unusable.

**Prose snippet to adapt (for a main-side committer that does NOT dispatch the ROADMAP owner):**

> When I commit, I follow the `commit-to-git` skill and pass `Agent: <my-name>` — it gives me the path-scoped form and the attribution trailer, so unrelated staged work is never pulled in and history records which role produced the commit. I never write `ROADMAP.md` myself — a direct write would race the single-owner model the pipeline relies on for that file's idempotency and merge safety.

## Role 2 — Worktree-side writer

**Fits:** any agent/skill that runs with CWD inside `.worktrees/<cycle>/`. Calibration examples: `developer`, `code-reviewer`, `test-runner`, `state-manager`, orchestrator-driven `plan-architect`.

**Required rule content:**

- The agent never writes `ROADMAP.md` or any file under `.project/product/cycles-in-progress/` from the worktree. A worktree-side write to them is a bug. The rule stands alone as a prohibition — the worktree agent does not name or reference whatever stage performs those writes on main, because it has no way to invoke another subagent and so cannot interact with it.
- If a merge conflict surfaces on `ROADMAP.md` or on any file under `.project/product/cycles-in-progress/`, the agent takes main's version unconditionally. Case-by-case resolution is wrong here — the worktree's version is wrong by construction, so the conflict signals a bug to investigate rather than text to merge.

**Prose snippet to adapt:**

> I run inside a worktree under `.worktrees/<cycle>/`. I never touch `ROADMAP.md` or anything under `.project/product/cycles-in-progress/` directly — a worktree-side write to them is a bug. If a three-way merge ever shows a conflict on one of them, the resolution is always "take main": a worktree-side change to those files is a bug to investigate, not an edit to preserve.

## Role 3 — Design-time writer

**Fits:** any agent/skill that writes specs, design, or plans on main *before* a worktree exists for the feature. Calibration examples: `spec-architect`, `design-architect`, user-driven `plan-architect`.

**Required rule content:**

- Before editing any document for a feature, the agent checks for an active worktree at `<main-root>/.worktrees/<cycle-slug>/`. If one exists, the agent refuses and directs the user either to finish execution and amend post-acceptance (producing a `<cycle>-amend-N` artifact) or to run `/abandon-feature` and restart. Editing docs on main while a worktree is in flight silently invalidates the worktree's inputs — the worktree was cut against a specific base, and changing that base underneath it breaks the contract its plan was written against.
- Because a design-time writer also commits on main, Role 1's path-scoped-commit rule applies as well. Embed both.

**Prose snippet to adapt:**

> Before I edit any document for a feature, I check for an active worktree at `<main-root>/.worktrees/<cycle-slug>/`. If one exists, I stop and direct the user to either finish the current run and amend after acceptance (producing a `<cycle>-amend-N` artifact) or `/abandon-feature` and restart. I never edit docs on main while a worktree for that feature is live, because the worktree was cut against a specific base and changing it underneath silently invalidates the plan that runs inside.

## Authoring checklist

For each role that applies:

- [ ] Rule content is present in prose, not as a label or reference.
- [ ] Each rule carries a short "why" (one clause is enough).
- [ ] No external file is cited for rule content.
- [ ] Multi-role agents section each role's rules under named headings.
- [ ] `agent-auditor` will verify by content; wording may vary, meaning must match.
