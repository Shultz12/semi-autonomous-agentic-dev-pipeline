# Promote Skill Mode

Promote a project-level convention to a user-level developer-skill when the convention has cross-project applicability.

## Trigger

User-invoked. The proposal commonly originates from the `## User-level items` section of a `knowledge-cleanup-proposal.md` written by `knowledge-curator`; the user reads the proposal and dispatches this mode against the relevant items. Proposals MAY also be provided directly by the caller without an originating cleanup proposal.

## Inputs

Read on-demand only:

- The proposal: rationale, target `<dev-type>` (`backend` | `frontend` | `infrastructure` | `test`), proposed user-level skill name, proposed content, and (when present) the repo-relative path of the originating project-level convention file.
- Knowledge-cleanup proposal at `.project/pipeline/knowledge-cleanup-proposals/<YYYY-MM-DD>-knowledge-cleanup-proposal-run-<K>.md` (when the proposal originates there).
- The cited project-level convention file (when present), for content review.

## Workflow

1. Read the proposal and any cited project-level convention files.
2. If `<dev-type>` is absent from the proposal, resolve it via caller dialogue. Accepted values: `backend`, `frontend`, `infrastructure`, `test`.
3. Dialogue with the caller per request: approve, reject, or modify.
4. On approval, write the new user-level skill at `.claude/skills/developer-skills/<dev-type>/<skill-name>/SKILL.md`. The frontmatter `metadata` block MUST include the field `promoted-from-project-path: <repo-relative path to the originating convention file>`. This is transitional metadata that lets `knowledge-curator` detect post-promotion redundancy on its next run; the field is removed during cleanup after the project-level convention is deleted, so the skill ultimately stands on its own.
5. The SKILL.md write triggers the cross-mode contract + index responsibility (see SKILL.md § "Contract & Index Maintenance"). Perform the contract write at `.claude/agents/interface-contracts/<skill-name>.contract.md`, the index row insert in `.claude/skills/find-subagent-contract/SKILL.md`, and the lookup verification in the same dialogue.
6. Return to the caller a chat-level message that names both paths — the new user-level skill, and the originating project-level convention (if any) — and states that the project-level convention will be flagged for removal by `knowledge-curator` on its next run. The caller may invoke `knowledge-curator` manually to expedite.

## Writes

- New `.claude/skills/developer-skills/<dev-type>/<skill-name>/SKILL.md` (with `promoted-from-project-path` in the frontmatter `metadata` block).
- New `.claude/agents/interface-contracts/<skill-name>.contract.md` (via the cross-mode contract trigger).
- Updated row in `.claude/skills/find-subagent-contract/SKILL.md` (via the cross-mode index trigger).

## What this mode does NOT write

No project-level writes of any kind. The originating project-level convention is cleaned up later via `knowledge-curator`'s post-promotion-redundancy proposal: the project-level item routes to `state-manager` (`refactor-curation` mode) for file + `_index.md` row removal; the user-level item is a plain-text directive in the proposal that the user or main agent executes directly as a one-line frontmatter edit (removing the now-irrelevant `promoted-from-project-path` line from the skill).
