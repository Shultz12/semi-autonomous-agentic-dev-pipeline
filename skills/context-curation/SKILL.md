---
name: context-curation
description: Prescribes the authoring discipline for `.project/knowledge/<type>/` convention files — structure, `created-during` frontmatter, `_index.md` row format with trigger phrases, cross-reference rules (Pattern A), and the citation self-verification protocol. Loaded on-demand by `state-manager` in `refactor-curation` mode; never preloaded via `skills:` frontmatter. Consumers Read this `SKILL.md` directly when authoring or modifying convention files.
domain: dev-tooling
user-invocable: false
---

# context-curation

Authoring discipline for project convention files under `.project/knowledge/<type>/` (where `<type>` is `backend`, `frontend`, `infrastructure`, or `tests`). The sole consumer is `state-manager` in `refactor-curation` mode; it Reads this `SKILL.md` directly and applies the rules below when creating or modifying convention files.

A convention file documents how the project handles a recurring concern (a validation pattern, a Hebrew-text edge case, a Prisma-relation rule, etc.). The discipline below exists because LLM agents author and consume these files — drift between cited code and the convention text silently misleads later runs, and unindexed files become dead weight no agent ever reads.

## Convention-file structure

Every convention file (NOT `_index.md`) carries these sections, in this order:

1. **Title** — concise noun phrase naming the convention.
2. **Purpose** — one to three sentences stating the rule and the concern it addresses.
3. **Code references** — file paths with line numbers (`backend/src/foo/bar.ts:42`) pointing at the canonical implementation(s) of the convention.
4. **Examples** — concrete instances of the convention being applied. Use code blocks with the actual project language.
5. **Anti-patterns** — concrete instances of violations, with a short note on why each is wrong.
6. **`## See also`** — cross-references to related conventions in other types. Each entry is a relative path with a one-line description. Omit this section when no cross-references apply.

## Mandatory frontmatter

Every convention file under `.project/knowledge/<type>/**/` (excluding `_index.md`) carries this frontmatter:

```yaml
---
created-during: <feature-slug>
---
```

`<feature-slug>` is the slug of the feature whose merge introduced the file (e.g., `pdf-extraction`, `credit-system`). For hand-authored convention files predating the pipeline, use `pre-pipeline`.

This field is unrecoverable after the fact — set it at creation. It is the only mechanism by which later cleanup runs can attribute a convention's provenance.

## `_index.md` row format

Each row in `_index.md` registers one convention with a trigger phrase that routes consumers (`developer`, `code-reviewer`) to read the file:

```markdown
- <trigger phrase> → <relative-path>.md
```

The trigger phrase maps to plan task language — phrases that actually appear in plan tasks targeting the convention's concern. Example: a convention covering Hebrew date formatting registers as `- format Hebrew date → hebrew-date.md`, not `- date utility → hebrew-date.md`, because plan tasks say "format Hebrew date", not "date utility". The mapping discipline is what makes the routing work: a developer reading the plan task picks up the convention because the trigger phrase echoes the task's verb-noun phrasing.

## Feature-specific conventions section

Parent `_index.md` files include a `## Feature-specific conventions` section that registers each child feature-directory. This prevents dead dirs (feature-local conventions that no agent ever reads because nothing routes to them):

```markdown
## Feature-specific conventions
(Read if your plan targets the named feature)
- credit-system → credit-system/_index.md
- pdf-extraction → pdf-extraction/_index.md
```

When a new feature-local convention directory is created under `.project/knowledge/<type>/<feature-slug>/`, add a corresponding row to the parent `_index.md`'s `## Feature-specific conventions` section. Without that row, the child `_index.md` is unreachable from the parent.

## Cross-reference discipline (Pattern A)

A convention may cite related conventions in OTHER types via the `## See also` section. This is cross-reference, NOT duplication.

**Pattern A: primary home + cross-references.** Cross-cutting conventions live in ONE primary type, with cross-reference rows in the other types' `_index.md` files pointing to the primary. Example: a Hebrew-text-direction convention has its primary home under `frontend/` (because rendering is the dominant concern), with cross-reference rows in `backend/_index.md` and `tests/_index.md` pointing to `frontend/hebrew-text-direction.md`. The full content lives in one place; the other types know where to find it.

**Promotion to root general.** A convention is promoted to `.project/knowledge/_index.md` (root, dev-type-agnostic) ONLY when every dev-type consumes it. A convention that two of three types use stays in Pattern A — promoting it prematurely pulls it out of the type-specific routing that the consumers actually use.

**Duplication is forbidden.** Copying convention content across types creates drift: one copy gets updated, the other doesn't, and consumers get conflicting guidance. If the urge to duplicate arises, use Pattern A instead.

## Self-verification protocol (author)

Every code reference and every named symbol in a convention file is a claim that the cited code exists and matches the convention's description. The author MUST verify each claim before recording it:

1. **Read each cited source file.** Open the file at the cited path with the Read tool. Confirm it exists and contains the construct the convention describes. A citation to a deleted or moved file silently misleads every later consumer.

2. **Grep each named symbol in the cited source.** For every function, class, const, type, or interface named in the convention, run a Grep against the cited source file confirming the symbol is defined or used there. A symbol named but absent is worse than no citation — it implies precision that isn't real.

3. **STOP on any symbol not found.** If a grep fails to locate a named symbol in its cited source, halt authoring. Do not record the convention with an unverified citation. Either find the correct source and amend the citation, or remove the claim. Propagating an unverified symbol corrupts the convention permanently — later consumers trust the citation and never re-verify.

This protocol is the highest-leverage point in the entire discipline. Skip it and the convention file becomes a confident-sounding but unreliable secondary source.

## Symbol-resolution check (mechanical)

The verification above is a human-level protocol. A mechanical version runs alongside it:

**Every code symbol token enclosed in backticks in a convention file MUST grep-resolve in the file it is cited from.**

Backticks are the scope marker. A token like `formatHebrewDate` enclosed in backticks is a code symbol claim and must be verifiable. A prose noun like "the validator" is not enclosed in backticks and is exempt — natural language has no symbol-resolution requirement.

This scoping is what makes the check mechanical: an author or later auditor walks the file, extracts every backtick-enclosed token, and runs a grep against its cited source. Tokens that fail are exactly the bugs the protocol exists to catch. The backtick convention is binding because without it, the check has no deterministic input set.

## Example

For a complete sample convention file demonstrating all of the above rules in one place, see [references/example-convention.md](references/example-convention.md). The reference is a copy-paste seed for authors creating a new convention from scratch; SKILL.md alone is sufficient for modifying or auditing an existing file.
