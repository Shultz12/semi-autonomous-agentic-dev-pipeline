---
name: use-pipeline-scripts
description: Owns AI-pipeline script templates (find-call-sites.ts, inventory-utils.ts, curate-approved.ts) and the bootstrap protocol that ports them into `.project/pipeline/scripts/` on first use. Loaded on-demand by `pattern-analyst` across its convergence-scout, divergence-scout, primitives-scout, and curate modes — never preloaded via `skills:` frontmatter. Consumers reference this skill rather than restating the protocol.
domain: dev-tooling
user-invocable: false
---

# use-pipeline-scripts

Centralizes the bootstrap protocol for AI-pipeline scripts and carries their templates. The sole consumer is `pattern-analyst` (across all four of its modes); each consuming persona contains only a one-line pointer to this skill.

## Bootstrap protocol

On first use of any script in a worktree, the consuming agent:

1. Reads this `SKILL.md` (this step — locates the template and its project-copy path).
2. Checks whether the project copy exists at the documented `.project/pipeline/scripts/<...>` path.
3. If missing: copies the template file verbatim to the project-copy path. The copy is byte-for-byte identical to the template at the user level.
4. If present: optionally compares the project copy's `// VERSION: <semver>` constant against the template's. Equal values → no action. Different values → no action by the bootstrapper (upgrade is a manual user step; see "Upgrades" below).
5. Runs the script with the documented parameters.

**Never overwrite an existing project copy.** Project copies may carry local edits; overwriting would silently destroy that work. The bootstrap is strictly copy-if-missing.

## Concurrency guarantee

Templates are version-pinned: each carries a top-of-file `// VERSION: <semver>` constant frozen at copy-time. Concurrent "copy if missing" operations from multiple worktrees produce byte-identical results regardless of which writer lands last. A bootstrapper MAY check the project copy's `VERSION` constant before any work; matching values mean no copy is needed. This check is recommended for clarity but not required for correctness — the operation is idempotent without it.

## Directory parity

The template directory tree under `templates/` mirrors the project-copy directory tree under `.project/pipeline/scripts/`. A codemod template lives under `templates/codemods/` because its project copy lives under `.project/pipeline/scripts/codemods/`. Analytical scripts live at `templates/` root because their project copies live at `.project/pipeline/scripts/` root. Parity is the contract that makes the template→project-copy mapping mechanical (same relative path, different root prefix).

## Auditor exception

`plan-auditor` is audit-only and NEVER bootstraps. If a script it needs is missing, the audit fails with `MISSING_SCRIPT_BOOTSTRAP` — the upstream bootstrapper should have run first. This exception is also stated in `plan-auditor`'s own essentials.

## Template index

| Template | Template path | Project-copy path | Bootstrapper(s) | Parameters |
|----------|---------------|-------------------|-----------------|------------|
| `find-call-sites.ts` | `templates/codemods/find-call-sites.ts` | `.project/pipeline/scripts/codemods/find-call-sites.ts` | `pattern-analyst` (`convergence-scout`, `primitives-scout` — whichever runs first) | `--function <name> --source <module-path> --tsconfig <path>` |
| `inventory-utils.ts` | `templates/inventory-utils.ts` | `.project/pipeline/scripts/inventory-utils.ts` | `pattern-analyst` (`divergence-scout` canonical; `primitives-scout` falls back) | `--tsconfig <path>` |
| `curate-approved.ts` | `templates/curate-approved.ts` | `.project/pipeline/scripts/curate-approved.ts` | `pattern-analyst` (`curate`) | `--findings <comma-separated paths> --audit <audit.md> --out <approved.md>` |

## Per-template specifications

### `find-call-sites.ts`

- **Consumers:** `pattern-analyst` (`convergence-scout`, `primitives-scout`).
- **Input:** name of the exported function and the module path declaring it; tsconfig path.
- **Backend:** `--tsconfig backend/tsconfig.json`.
- **Frontend:** `--tsconfig frontend/tsconfig.json` (extends `.svelte-kit/tsconfig.json`; **prerequisite:** `svelte-kit sync` runs before this script so the generated tsconfig exists).
- **Mechanics:** loads tsconfig (resolves path aliases via the TS language service). For `.ts`/`.tsx`/`.js`: `ts-morph` + `Project.findReferences()`. For `.svelte`: `svelte2tsx` preprocessing (Svelte 5 with runes supported) — globs `**/*.svelte` excluding `node_modules`, `.svelte-kit`, `build`, `dist`; each file is preprocessed in `ts` mode and added to the ts-morph Project as a virtual `<original>.svelte.tsx`; references are found uniformly across real `.ts` and virtual `.tsx`; for virtual-file matches, the source map translates positions back to original `.svelte` `file:line:col`. Dynamic imports / `require()` of the source module are flagged as `uncertain`.
- **Output:** stable, sorted JSON to stdout:

  ```json
  {
    "function": "add",
    "source": "src/shared/math/add.ts",
    "callSites": {
      "ts": [{ "file": "...", "line": 42, "column": 18 }],
      "svelte": [{ "file": "...", "line": 22, "column": 14 }],
      "uncertain": [{ "file": "...", "reason": "dynamic import" }]
    },
    "totals": { "ts": 27, "svelte": 5, "uncertain": 2, "total": 34 }
  }
  ```

- **Errors (structured stderr + non-zero exit):** `FUNCTION_NOT_FOUND`, `SOURCE_NOT_FOUND`, `AMBIGUOUS_EXPORT`, `TSCONFIG_INVALID`. A missing npm dependency (e.g., `ts-morph`, `svelte2tsx`) surfaces as `MODULE_NOT_FOUND: <module>`; the consuming agent surfaces the error and proceeds per the project's normal "install missing dep" flow.
- **Stability:** identical input produces byte-identical output (sorted call-site list).

### `inventory-utils.ts`

- **Consumers:** `pattern-analyst` (`divergence-scout` canonical; `primitives-scout` falls back).
- **Input:** tsconfig path (e.g., `--tsconfig backend/tsconfig.json`).
- **Architecture marker contract:** reads `.project/knowledge/architecture.md` and looks for a `## Shared utility locations` heading followed by a glob list (one path or glob per line, leading `- ` allowed). Example:

  ```
  ## Shared utility locations
  - backend/src/shared/**/*.ts
  - frontend/src/lib/shared/**/*.ts
  ```

  Missing heading → exit non-zero with `ARCHITECTURE_MARKER_MISSING`. Heading present but listing no globs → `ARCHITECTURE_MARKER_EMPTY`.
- **Companion marker (`## Validation locations`):** same shape, read by `pattern-analyst`'s Layer 1 centralized-validators rule — NOT by this script. Documented here so both architecture-derived path contracts are listed in one place. Absence of `## Validation locations` is permitted (the consuming rule degrades gracefully).
- **Mechanics:** loads tsconfig (resolves path aliases via the TS language service); same Svelte handling as `find-call-sites.ts`. Enumerates exported declarations (functions, classes, const symbols) at the architecture-declared paths.
- **Output:** stable, sorted JSON to stdout:

  ```json
  {
    "scannedPaths": ["backend/src/shared/**/*.ts", "frontend/src/lib/shared/**/*.ts"],
    "utilities": [
      {
        "name": "formatHebrewDate",
        "path": "backend/src/shared/format/hebrew-date.ts",
        "kind": "function",
        "signature": "(d: Date, opts?: HebrewDateOptions) => string"
      }
    ],
    "totals": { "functions": 18, "classes": 4, "constants": 7, "total": 29 }
  }
  ```

- Sorted by `name` ascending; identical input produces byte-identical output.
- **Errors (structured stderr + non-zero exit):** `ARCHITECTURE_FILE_NOT_FOUND`, `ARCHITECTURE_MARKER_MISSING`, `ARCHITECTURE_MARKER_EMPTY`, `INVALID_PATH_GLOB`, `TSCONFIG_INVALID`. Missing npm deps surface as `MODULE_NOT_FOUND: <module>`.

### `curate-approved.ts`

- **Consumer:** `pattern-analyst` (`curate`) — sole bootstrapper and sole runner.
- **Input:** `--findings <comma-separated paths>` (one or more findings files; no spaces between commas), `--audit <audit.md>`, `--out <approved.md>`. Each scout mode writes its own findings file; curate combines them through this script. Finding IDs MUST be globally unique across all input findings files.
- **Strict input contract:** the audit file MUST contain ONLY `ACCEPT` and `REJECT` verdicts at script-invocation time. `MODIFY-AS` is the curate-mode agent's responsibility to resolve before the script runs.
- **Process:**
  1. Read each findings file. Index every finding by its `id` across all files; on duplicate ID across files, exit non-zero with `FINDING_ID_COLLISION: <id> in <file-A>, <file-B>`.
  2. Validate the audit file: scan all verdict lines; if any verdict is `MODIFY-AS:<...>` → exit non-zero with `UNRESOLVED_MODIFY_AS` (stderr lists offending finding IDs).
  3. Pair each finding with its audit verdict. Verdict references a finding ID that doesn't exist, or a finding has no audit verdict → `FINDINGS_AUDIT_MISMATCH: <id>`.
  4. Filter: keep findings whose verdict is `ACCEPT`; drop findings whose verdict is `REJECT`. No shape substitution — the agent has already applied corrections.
  5. Emit `approved.md` containing only the surviving (ACCEPT) findings, each preserved verbatim, with an `<!-- origin: <findings-file-path> -->` comment line above each block for traceability.
- **Empty-result handling:** when zero `ACCEPT` verdicts remain, `curate-approved.ts` still produces `approved.md` containing the `NO_PROPOSALS_APPROVED` marker:

  ```markdown
  # Pattern Findings — Approved
  **Status:** NO_PROPOSALS_APPROVED
  **Audit summary:** <count> findings rejected (<breakdown>)
  **Implementer action:** Orchestrator should commit findings + audit + this approved.md to the refactor or primitives worktree; ship via accept-feature.
  ```

- **Determinism:** identical inputs produce byte-identical output.
- **Errors (structured stderr + non-zero exit):** `UNRESOLVED_MODIFY_AS`, `FINDINGS_AUDIT_MISMATCH`, `FINDINGS_NOT_FOUND`, `AUDIT_NOT_FOUND`, `FINDING_ID_COLLISION`.

## Runtime dependencies

The skill does NOT declare or install npm dependencies on the user's behalf. Each script is authored to fail with a clear, actionable error when a required dep is missing (e.g., `MODULE_NOT_FOUND: ts-morph`). When such a failure occurs at runtime, the consuming agent surfaces the error and proceeds per the project's normal "install missing dep" path (asking the user for permission to install). This `SKILL.md` does NOT enumerate project `devDependencies`.

Known runtime dependencies (informational only; the consuming agent installs them on first failure):

- `find-call-sites.ts`: `ts-morph`, `svelte2tsx`. Directory enumeration is dep-free (recursive `node:fs` walk).
- `inventory-utils.ts`: `ts-morph`, `svelte2tsx`. `.ts`/`.tsx` glob resolution uses ts-morph's native path matching; `.svelte` enumeration is a dep-free `node:fs` walk.
- `curate-approved.ts`: none beyond the Node.js standard library.

## Upgrades

Project copies are frozen at copy-time and are project-agnostic by design (paths come from `architecture.md`; tsconfig comes from invocation parameters). Upgrades are manual: the user re-copies the template to override the project copy. The bootstrapping agent includes the freshly-copied project copy in its own path-scoped self-commit for the invocation that triggered the bootstrap, so writer == committer holds for the bootstrap write as well — there is no separate script-only commit. When the project copy already existed at invocation start, the bootstrap was a no-op and the script path is NOT in the commit set.
