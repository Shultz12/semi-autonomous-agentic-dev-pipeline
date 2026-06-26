# Pipeline Conformance Checklist

Applies only when the audited artifact participates in the feature pipeline. A pipeline artifact is any agent or skill that writes under `.project/cycles/*`, writes under `.project/product/*`, commits to main on behalf of a feature, or runs with CWD inside `.worktrees/<cycle>/`. If the audited artifact is not a pipeline participant, record pipeline conformance as N/A and move on.

## Role classification

Determine which of the three roles the artifact embodies. An artifact may embody more than one; apply every role whose signals are present.

- **Role A — Committer (main-side or worktree-side).** Signals: any `git commit` invocation, or prose stating the artifact commits its own artifacts — whether main-side (`git -C <main-root> commit`, for files whose canonical home is main) or worktree-side (`git commit` from a worktree CWD, for files that live inside the worktree).
- **Role B — Worktree-side writer.** Signals: references to worktree CWD, writes under `.project/cycles/*/execution/` or similar worktree-only paths.
- **Role C — Design-time writer.** Signals: writes under `.project/cycles/*/specs/` or `plans/` on main before a worktree exists.

Record the detected roles. Every subsequent check is role-gated.

## Audit principle

The audit is on **content presence**, not wording. The artifact's prose must convey the required rule in its own voice. Do not fail a check because the phrasing differs from the snippets in the authoring templates; fail only when the content is absent, incomplete, or contradicted.

## Checks by role

### If Role A (main-side committer) applies

- **PC.A1** Artifact obtains its commit form from the `commit-to-git` skill (subagents Read it at the commit step; chat-driving skills invoke it via the Skill tool) rather than inlining the path-scoped form, the `git -C` variants, or the trailer mechanics. ERROR if the artifact restates that git rule content inline instead of referencing the skill. CRITICAL if it commits with no reference to the skill's discipline at all.
- **PC.A2** A single dedicated stage (`progress-tracker`) is the sole writer of `ROADMAP.md` — its creation and every transition. If the audited artifact IS that owner, its prose must state it writes the ROADMAP directly under its own mkdir-lock protocol — PASS. If the artifact dispatches the owner (e.g., `product-architect` dispatching `init`), its prose must state it hands the ROADMAP off rather than writing it, and may name the owner. Every other artifact must state it never writes `ROADMAP.md` directly and, per the information-hiding rule, must NOT name the owner — it neither writes the ROADMAP nor dispatches the owner, so the reference would be unusable. A direct ROADMAP write by any agent other than the owner is a CRITICAL violation. N/A if the artifact never touches ROADMAP.

- **PC.A3** Every fresh-message commit passes `Agent: <name>` to the `commit-to-git` skill (recorded as the attribution trailer). ERROR if a fresh-message commit is authored without it. `git commit --amend --no-edit` correctly omits re-adding the trailer — do not flag those.

- **PC.A4** Every return-message template documented in the artifact (or its interface contract) carries a `Commit:` field per convention 0.3.7. The documented values must include at least: `<short-hash>` on success, `skipped` when the write produced no diff against HEAD, `none` when the invocation produced no artifact, and `failed` when the commit attempt failed. The dispatcher relies on this field as its interrupted-commit-recovery signal — re-dispatching when it is absent — so an undocumented or partial field defeats recovery. ERROR if the field is absent from any return template; WARNING if values are partially documented (one or more of the four values is missing). N/A if the artifact has no return-message templates (e.g., a chat-driving skill that returns conversational output rather than a structured message).

### If Role B (worktree-side writer) applies

- **PC.B1** Artifact prose states it never writes `ROADMAP.md` or `.project/product/cycles-in-progress/*` from the worktree. CRITICAL if the prohibition is absent. The prose must NOT name the stage that performs those writes on main: a worktree subagent neither writes those files nor dispatches their writer, so naming it leaks an unusable reference — WARNING if `progress-tracker` is named in a worktree-side rule.
- **PC.B2** Artifact prose states that merge conflicts on `ROADMAP.md` or `.project/product/cycles-in-progress/*` resolve by taking main's version unconditionally. ERROR if absent; WARNING if present without rationale (e.g., "the worktree's version is wrong by construction").

### If Role C (design-time writer) applies

- **PC.C1** Artifact prose states that it checks for an active worktree at `<main-root>/.worktrees/<cycle-slug>/` before editing, and refuses to write while one exists, directing the user to amend post-acceptance or `/abandon-feature`. CRITICAL if absent.
- **PC.C2** Role C also commits on main — PC.A1 applies. Re-use the Role A finding; do not double-count.

### Global (applies to every pipeline artifact)

- **PC.G1** Artifact does not cite shared rule labels ("P4", "per P6", "see GUARDRAILS.md", "see FILE-OWNERSHIP.md") or any external rulebook file. ERROR per citation.
- **PC.G2** Multi-role artifacts section each role's rules under named headings so a reader can tell which branch of behavior applies. WARNING if role content is interleaved without headings.
- **PC.G3** Project-level writers must self-commit. Detection: the artifact's workflow contains any `Write` / `Edit` target under `.project/`, project source, or project-level `.claude/`. When detected, the artifact MUST also embody Role A (Committer) — i.e., its prose must describe committing the file(s) it wrote via the `commit-to-git` skill. The default is on: every project-level write needs a self-commit. The only legitimate omission is an artifact that writes solely to user-level paths (`.claude/...`) or produces no files, in which case Role A does not apply and this check is N/A. CRITICAL if the artifact writes project-level files but no commit step is present anywhere in its workflow or essentials.

## Reporting

Include a dedicated "Pipeline Conformance" block in the review output when any role applies, listing each check with status (PASS/FAIL/WARNING/N/A), the role it was gated on, and a file:line reference for every FAIL. If no role applies, emit a single line: `Pipeline conformance: N/A (artifact is not a pipeline participant)`.
