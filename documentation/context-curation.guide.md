# context-curation Guide

## What It Does

`context-curation` is a non-user-invocable skill that defines the authoring discipline for project convention files — the per-dev-type guidance documents that live under `.project/knowledge/<type>/` (where `<type>` is `backend`, `frontend`, `infrastructure`, or `tests`).

The skill itself is documentation: rules for how to structure a convention file, how to register it in `_index.md`, how to cross-reference between types, and how to verify every cited symbol resolves in the source it claims. The pipeline's `state-manager` agent (in `refactor-curation` mode) is the sole consumer; it Reads `SKILL.md` on demand whenever it is about to create or modify a convention file.

## Why It Exists

Convention files are written and consumed by LLM agents. Two failure modes are particularly costly here:

- **Drift between cited code and convention text.** A convention that names a function the codebase no longer exports silently misleads every later consumer. The damage compounds because later runs trust the citation and never re-verify.
- **Dead files no agent ever reads.** A convention authored without an `_index.md` row, or under a feature-dir that the parent `_index.md` doesn't register, becomes unreachable. The work that went into authoring it is invisible to the routing.

The discipline addresses both: a citation-verification protocol (Read + grep, STOP on missing) catches drift at author-time, and the indexing rules guarantee every convention is reachable from the type-level routing the consumers actually walk.

## The Discipline (overview)

| Rule category | What it governs |
|---|---|
| Convention-file structure | Required sections (title, purpose, code references, examples, anti-patterns, `## See also`) and their order |
| Mandatory frontmatter | Every convention file (except `_index.md`) carries `created-during: <feature-slug>` — provenance is unrecoverable later |
| `_index.md` row format | Trigger phrase → file path; trigger phrasing must echo plan task language so `developer`/`code-reviewer` read protocols route to it |
| Feature-specific conventions section | Parent `_index.md` lists each child feature-dir so feature-local conventions aren't dead dirs |
| Cross-reference discipline (Pattern A) | Primary home in ONE type + cross-reference rows in other types' `_index.md` — duplication is forbidden |
| Self-verification protocol | Author Reads each cited source file; greps each named symbol; STOPs on any symbol not found |
| Symbol-resolution check (mechanical) | Every backtick-enclosed code symbol must grep-resolve in its cited source — backticks are the deterministic scope marker |

`SKILL.md` carries each rule with a short example. A complete sample convention file showing all rules in one place lives at `references/example-convention.md`.

## How It's Used

The pipeline's `state-manager`, in `refactor-curation` mode, is the sole consumer. The flow:

1. A refactor or primitives proposal has been approved that introduces or modifies a convention.
2. `state-manager` enters `refactor-curation` mode and Reads `.claude/skills/context-curation/SKILL.md` directly (the skill is NOT in `state-manager`'s `skills:` frontmatter — load is on-demand).
3. `state-manager` authors or modifies the relevant convention file(s) under `.project/knowledge/<type>/...`, applying every rule in the skill.
4. For new convention files, `state-manager` registers them in the appropriate `_index.md` and (if the file lives under a new feature-dir) adds the corresponding row to the parent `_index.md`'s `## Feature-specific conventions` section.
5. `state-manager` runs the self-verification protocol against every citation before finalizing the file.

The skill itself never executes — it prescribes; the consuming agent applies.

## Limitations

- **No mechanical enforcement at skill level.** The skill is content discipline; it cannot fail a build or block a commit on its own. The consuming agent (`state-manager`) is responsible for applying the rules and halting on verification failures. Drift is caught at author-time, not at commit-time.
- **Backtick-scope assumes consistent author discipline.** The mechanical symbol-resolution check works only when authors actually wrap code symbols in backticks. A symbol mentioned in plain prose escapes the check; the human-level Read+grep protocol is the backstop, but it relies on the author noticing.
- **Pattern A promotion to root general is judgment.** "Every dev-type consumes it" is a judgment call. The skill states the rule but cannot decide for a specific convention whether a third type's usage is incidental or sustained — that decision lives with the author and reviewers.
- **No `_index.md` shape rules beyond row format.** The skill governs how rows are written but does not prescribe `_index.md`'s overall sectioning (headings, intro text, etc.). Existing `_index.md` files in the project set those conventions.

## Related Files

| File | Purpose |
|------|---------|
| `.claude/skills/context-curation/SKILL.md` | Skill definition: the seven rule categories with inline examples |
| `.claude/skills/context-curation/references/example-convention.md` | Copy-paste seed: a complete sample convention file demonstrating every rule |
| `.claude/agents/state-manager/` | The sole consumer (in `refactor-curation` mode) |
| `.claude/documentation/state-manager.guide.md` | Consumer guide |
| `.claude/documentation/use-pipeline-scripts.guide.md` | Peer skill (same archetype: non-user-invocable, consumed by another pipeline agent) |
