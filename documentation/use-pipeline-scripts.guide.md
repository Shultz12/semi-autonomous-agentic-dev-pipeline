# Use Pipeline Scripts Guide

## What It Is

`use-pipeline-scripts` is a non-user-invocable skill that owns the three analytical/codemod scripts the AI pipeline runs during the post-merge scout-and-refactor and primitives-extraction flows, plus the **bootstrap protocol** that ports those scripts into a project on first use.

The skill itself contains no executable logic — it is documentation plus a `templates/` directory holding the actual TypeScript files. The pipeline's `pattern-analyst` agent is the sole consumer; its persona carries a one-line pointer to this skill and reads `SKILL.md` on demand the first time it needs one of the scripts.

## Why It Exists

Pipeline scripts have to live somewhere portable: written once at the user level, copied verbatim into each project that runs the pipeline. Centralizing them here means:

- The bootstrap protocol is stated **once** (in `SKILL.md`), not duplicated across every agent that runs a script.
- Templates are **version-pinned** (`// VERSION: <semver>` at the top of each file), so concurrent "copy if missing" operations from multiple worktrees are race-safe and idempotent.
- Project copies are intentionally frozen at copy-time and project-agnostic (paths come from `architecture.md`; tsconfig comes from invocation parameters), so a project can edit its copy locally without the user-level template clobbering it.

## The Three Scripts

| Script | Project copy path | Purpose | Run by |
|--------|-------------------|---------|--------|
| `find-call-sites.ts` | `.project/pipeline/scripts/codemods/find-call-sites.ts` | Enumerate every call site of an exported function across `.ts`/`.tsx`/`.js` (via ts-morph) and `.svelte` (via svelte2tsx). Dynamic `import()`/`require()` are flagged as `uncertain`. Output is stable sorted JSON. | `pattern-analyst` — `convergence-scout`, `primitives-scout` |
| `inventory-utils.ts` | `.project/pipeline/scripts/inventory-utils.ts` | List exported functions/classes/const symbols at the paths declared under `## Shared utility locations` in `.project/knowledge/architecture.md`. Output is stable sorted JSON. | `pattern-analyst` — `divergence-scout` (canonical), `primitives-scout` (fallback) |
| `curate-approved.ts` | `.project/pipeline/scripts/curate-approved.ts` | Combine one or more findings files, pair each finding with its audit verdict, keep only `ACCEPT` findings, and emit `approved.md` (or a `NO_PROPOSALS_APPROVED` marker if every finding was rejected). Deterministic. | `pattern-analyst` — `curate` |

Template paths mirror project-copy paths under `templates/`: `templates/codemods/find-call-sites.ts`, `templates/inventory-utils.ts`, `templates/curate-approved.ts`. The mirror is the contract that makes the template→project-copy mapping mechanical (same relative path, different root prefix).

## The Bootstrap Protocol

The first time an agent needs a script in a worktree, it:

1. Reads `SKILL.md` to locate the template and its project-copy path.
2. Checks whether the project copy already exists.
3. If missing → copies the template verbatim to the project-copy path.
4. If present → optionally compares `// VERSION` constants; either way, takes no overwriting action (upgrades are manual).
5. Runs the script.

**Bootstrap never overwrites an existing project copy.** Project copies may carry local edits; overwriting would silently destroy that work.

**Bootstrapper-by-convention** (whichever runs first wins for shared scripts):

- `find-call-sites.ts` → `convergence-scout` or `primitives-scout`.
- `inventory-utils.ts` → `divergence-scout` (canonical); `primitives-scout` falls back when no `divergence-scout` has ever run.
- `curate-approved.ts` → `curate`.

**Auditor exception:** `plan-auditor` is audit-only and never bootstraps. If a script it needs is missing, its audit fails with `MISSING_SCRIPT_BOOTSTRAP` — the upstream bootstrapper should have run first.

## Runtime Dependencies

The skill does **not** install npm packages on your behalf. Each script fails fast with a clear error (`MODULE_NOT_FOUND: <module>`) when a required dependency is missing; the consuming agent then surfaces the error and follows the project's normal "ask before installing a dependency" flow.

- `find-call-sites.ts` and `inventory-utils.ts` need `ts-morph` and `svelte2tsx`. Directory enumeration is dependency-free (recursive `node:fs` walk).
- `curate-approved.ts` needs nothing beyond the Node.js standard library.
- Frontend invocations of `find-call-sites.ts` use `frontend/tsconfig.json`, which extends `.svelte-kit/tsconfig.json` — so `svelte-kit sync` must have run first to generate it.

## Upgrades

To pick up a newer version of a script, the user manually re-copies the template over the project copy. There is no automatic upgrade and no separate script-only commit — the project copy commits naturally alongside the next code change.

## Limitations

- The skill does not validate that a project's `architecture.md` carries the `## Shared utility locations` marker `inventory-utils.ts` depends on; the script itself fails with `ARCHITECTURE_MARKER_MISSING` / `ARCHITECTURE_MARKER_EMPTY` at runtime if it's absent or empty.
- Source-map translation in `find-call-sites.ts` (virtual `.svelte.tsx` → original `.svelte` position) is best-effort: exact mappings are used when available, otherwise the generated position is returned (line correct, column possibly approximate).
- Findings/audit parsing in `curate-approved.ts` assumes the documented Markdown grammar: findings as `### ` blocks each carrying an `id:` line; audit as `## Verdict: <id>` blocks each carrying a `Verdict: ACCEPT|REJECT|MODIFY-AS:<...>` line.

## Related Files

| File | Purpose |
|------|---------|
| `.claude/skills/use-pipeline-scripts/SKILL.md` | Skill definition: bootstrap protocol, template index, per-template specs |
| `.claude/skills/use-pipeline-scripts/templates/codemods/find-call-sites.ts` | Template — call-site enumeration |
| `.claude/skills/use-pipeline-scripts/templates/inventory-utils.ts` | Template — shared-utility inventory |
| `.claude/skills/use-pipeline-scripts/templates/curate-approved.ts` | Template — findings curation by audit verdict |
| `.claude/agents/pattern-analyst/` | The sole consumer (when that agent is created) |
