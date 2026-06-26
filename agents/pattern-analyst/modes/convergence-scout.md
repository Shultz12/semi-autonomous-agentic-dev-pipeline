# Mode: convergence-scout

Detects convergent code: the same logic appearing in multiple places, candidate for
extraction (consolidation under a new name) or ABSTRACT (generalization of an existing
narrow utility). Runs all three detection layers. Writes findings to its own file at
`.project/cycles/<slug>/refactor-proposals/pattern-findings-convergence.md`. Does NOT read or
append to any other scout's file.

## Inputs

```
Mode: convergence-scout
slug: <slug>
```

- The codebase at HEAD in the current worktree.
- `.project/knowledge/architecture.md` — used to learn validation locations and shared-util
  paths (heading contracts are read on-demand).
- `.project/knowledge/<type>/_index.md` files — to surface conventions worth referencing.
- Existing primitives via `.project/pipeline/scripts/inventory-utils.ts` — read-only consumer in
  this flow (the script's owner is `divergence-scout`, which runs first in the
  scout-and-refactor flow dispatch).
- `find-call-sites.ts` via `.project/pipeline/scripts/codemods/find-call-sites.ts` — invoked only
  when an ABSTRACT candidate is identified. **This mode is the sole owner and
  bootstrapper of `find-call-sites.ts` in the scout-and-refactor flow.**

## Bootstrap Responsibility

- Sole bootstrapper of `find-call-sites.ts` in the scout-and-refactor flow. On first use,
  follow `.claude/skills/use-pipeline-scripts/SKILL.md`'s copy-if-missing protocol.
- Read-only consumer of `inventory-utils.ts`. If the project copy is missing when this
  mode runs, error with `SCRIPT_NOT_FOUND: inventory-utils.ts` — that signals the
  dispatch order was violated (divergence-scout must run first).

## Dispatch Order

In the scout-and-refactor flow, `divergence-scout` runs FIRST (it owns
`inventory-utils.ts`); `convergence-scout` runs SECOND and consumes the bootstrapped
copy. This order is also the natural reading order — divergence answers "did this feature
use what already exists?" before convergence answers "what new patterns did this feature
introduce?"

## Workflow

1. **Register output path** — Bash: `mkdir -p .project/cycles/<slug>/refactor-proposals/ && echo ".project/cycles/<slug>/refactor-proposals/pattern-findings-convergence.md" > /tmp/.claude-agent-output-target`. The `mkdir -p` creates the cycle's `refactor-proposals/` subdirectory at scout-start — for a refactor/primitives cycle `.project/cycles/<slug>/` may not exist yet.

2. **Read context** — Read `.project/knowledge/architecture.md` (full file) to ground:
   - `## Shared utility locations` heading (for `inventory-utils.ts`)
   - `## Validation locations` heading (for Layer 1 centralized-validators rule;
     absent → rule is project-wide)

3. **Verify `inventory-utils.ts` is bootstrapped** — Glob
   `.project/pipeline/scripts/inventory-utils.ts`. Missing → escalate with
   `Reason: SCRIPT_NOT_FOUND: inventory-utils.ts (divergence-scout dispatch order violated)`.

4. **Run Layer 1 — Known architectural regex patterns** (see *Detection layers* below).
   Build a candidate list per regex; cluster occurrences at the same conceptual site so
   you emit one finding per cluster, not one per occurrence.

5. **Run Layer 2 — Structural duplication (jscpd)** — invoke via Bash with the documented
   parameters (see *Layer 2* below). On `MODULE_NOT_FOUND: jscpd`, surface the error and
   stop the layer (the orchestrator handles the install path).

6. **Run Layer 3 — Inline semantic inspection** — for Layer 1 ambiguous clusters or
   Layer 2 high-similarity clusters not matched by Layer 1. ≤5 inspections per run; defer
   excess to the next cycle. Record each inspection inline regardless of decision (see
   *Layer 3* below).

7. **Classify each surviving cluster — EXTRACT vs ABSTRACT candidate.**
   - If `inventory-utils.ts` shows an existing narrow utility the cluster could collapse
     onto → treat as **ABSTRACT candidate**. Proceed to step 8.
   - If no existing narrow utility exists → emit a conventional **EXTRACT** finding (no
     ABSTRACT evaluation, no `find-call-sites.ts` run).

8. **ABSTRACT candidate evaluation** — for each ABSTRACT candidate:
   1. Read `.claude/agents/pattern-analyst/references/abstract-migration.md`
      (on-demand; not preloaded). Apply the hard gates + scoring axes.
   2. Verify the frontend prerequisite: Glob `.svelte-kit/tsconfig.json`. Missing → run
      `pnpm --filter frontend exec svelte-kit sync`.
   3. Bootstrap `find-call-sites.ts` per `.claude/skills/use-pipeline-scripts/SKILL.md`
      if the project copy is missing.
   4. Run `find-call-sites.ts --function <source-function> --source <source-module-path>
      --tsconfig <appropriate-tsconfig>` for each tsconfig the function is callable from
      (backend, frontend, or both). Capture stable JSON output.
   5. Evaluate the candidate against the matrix. Emit the finding using the structured
      ABSTRACT finding contract from `references/abstract-migration.md` — full payload on
      `verdict: APPROVE`; minimal subset (`source-file`, `source-function`,
      `current-signature`, `verdict: REJECT`, `reject-reason: <text>`) on
      `verdict: REJECT`.
   6. If `verdict: REJECT`, ALSO emit a separate **EXTRACT** finding with the next
      sequential `CF-<n>` ID consolidating the cluster as a new util with a distinct
      name. REJECT on ABSTRACT does not mean "do nothing"; both findings remain in the
      file for transparency.

9. **Run disconfirmation pass.** For each candidate finding produced in steps 4-8,
   consider a counter-argument and confirm the proposed directive is the least-invasive
   adequate response (REUSE before EXTRACT before ABSTRACT). Drop any finding that does
   not survive the counter-argument. Run this pass AFTER classification and BEFORE
   writing — findings dropped here never reach the auditor.

10. **Normalize target files to a clean starting state.** Determine the file set this
    invocation will write:

    - Always: `.project/cycles/<slug>/refactor-proposals/pattern-findings-convergence.md`.
    - When `find-call-sites.ts` was bootstrapped (copy-if-missing) this invocation: also
      `.project/pipeline/scripts/codemods/find-call-sites.ts`.

    For each path `P` in the set, run via Bash:

    ```
    if [ -f "<P>" ]; then
      if git ls-files --error-unmatch "<P>" >/dev/null 2>&1; then
        git checkout HEAD -- "<P>"
      else
        rm -f "<P>"
      fi
    fi
    ```

    - File doesn't exist → no-op (the common case for a new invocation).
    - File tracked at HEAD → `git checkout HEAD -- <path>` discards uncommitted changes;
      previously-committed content survives unchanged.
    - File untracked → `rm` removes the orphan from a crashed prior write (it was never in
      the audit trail).

    Apply the normalize step AFTER any bootstrap copy this invocation performs but BEFORE
    writing the findings file. The bootstrap path is in the file set only when the copy
    actually fired (project copy was missing); when the project copy already existed at
    invocation start, the bootstrap was a no-op and the path is not in the file set.

11. **Write findings file** — write
    `.project/cycles/<slug>/refactor-proposals/pattern-findings-convergence.md` fresh. Do NOT
    append to any other file. IDs are sequential starting from `CF-1`.

12. **Commit the artifacts.** Read `.claude/skills/commit-to-git/SKILL.md` and follow
    it to commit every path written this invocation in one path-scoped commit. Pass:

    - `Agent: pattern-analyst`
    - `Subject: refactor(<slug>): convergence findings`
    - `Path:` every path written by this invocation. The set is:
      - Always: `.project/cycles/<slug>/refactor-proposals/pattern-findings-convergence.md`.
      - When `find-call-sites.ts` was bootstrapped this invocation: also
        `.project/pipeline/scripts/codemods/find-call-sites.ts`.

    Where `<slug>` is the value of the dispatch input's `slug:` field.

    Commit nothing else. One commit per invocation. Capture the resulting short hash for
    the return. If the commit produced no change (the normalized files matched HEAD and
    the fresh writes reproduced them byte-for-byte), record `skipped`. If the commit
    fails (lock contention, hook rejection, transient error), record `failed` and surface
    it in the return — never report a success hash for a commit that did not happen.

    A failed commit must never block the return from happening; the artifacts are already
    written and the SubagentStop hook is satisfied.

13. **Return** — emit the return message (below).

## Detection Layers

### Layer 1 — Known architectural regex patterns

| Pattern | Detection | Propose at |
|---|---|---|
| Centralized validators (email / password / username / tenant-id / session keys / uploaded-file name) | Inline regex literal touching one of these domains, anywhere outside the validation paths declared in `architecture.md` under the `## Validation locations` heading. If the heading is absent, treat the rule as project-wide. | 2 occurrences (zero tolerance) |
| Hebrew date formatting | `toLocaleDateString('he-IL'...)` or `Intl.DateTimeFormat('he-IL'...)` | 2 occurrences |
| Role comparison | `\brole\s*===\s*['"](owner\|admin\|member)['"]` | 2 occurrences |
| Try-catch with Result-wrap | `try \{[\s\S]+?\} catch[\s\S]+?Result\.fail` multiline | 3 occurrences |
| Inline RTL class (ml/mr in `.svelte`/`.tsx`) | `\bm[lr]-\d` | 3 occurrences |
| Hardcoded Tailwind color class (broad-shape) | `\b(text\|bg\|border\|ring\|fill\|stroke\|divide\|placeholder\|accent\|caret)-[a-z]+-\d{2,3}\b` — accepts some false positives on intentional uses; custom palette names (e.g., `brand`, `accent`) are not enumerated statically — any class matching the shape is a candidate | 3 occurrences |
| Raw `lucide-svelte` import | `from ['"]lucide-svelte['"]` | 2 occurrences (zero tolerance) |
| Prisma query missing `organizationId` | **Two-step.** Step 1: regex `(findFirst\|findMany)\(\{[\s\S]*?where:[\s\S]*?\}` to match any Prisma find with a `where` clause. Step 2 (post-filter): for each Step 1 match, examine the captured body between the outermost `{` after `where:` and its matching `}`; if the substring `organizationId` is NOT present, report. If IS present, drop. Implement Step 2 as a small parser fragment (single forward scan tracking brace depth), NOT a regex extension. | Report always (security) |

Implementation notes:
- Strip markdown escapes when implementing (`\|` → `|`).
- One finding per distinct cluster, not N findings per occurrence. The "Propose at"
  column is the trigger threshold, not the finding-count multiplier.

### Layer 2 — Structural duplication (jscpd)

- Minimum block size: 8 lines.
- Minimum occurrences: 3.
- Similarity threshold: ≥70%.
- Excluded paths: `**/*.spec.ts`, `**/*.test.ts`, `**/*.stories.*`, `**/fixtures/**`,
  `**/migrations/**`, `**/*.config.*`.
- Block must contain ≥2 statements (filters import-only clusters).

Invocation: `jscpd` is an external CLI (npm package `jscpd`), not a pipeline-owned
script. Invoke via Bash with the parameters above. No template lives in
`use-pipeline-scripts/templates/` and no bootstrap protocol applies. If `jscpd` is not
installed, the invocation surfaces `MODULE_NOT_FOUND: jscpd` per the standard
runtime-dependency contract; proceed per the project's normal "install missing dep" flow.

### Layer 3 — Semantic inspection

- **Mechanism.** Performed inline by you within the same mode invocation — no sub-agent
  spawn, no separate LLM call. Your own reasoning is the inspector.
- **Trigger.** Layer 1 flags an ambiguous cluster OR Layer 2 surfaces a high-similarity
  cluster with no Layer 1 match.
- **Budget.** ≤5 inspections per run; defer excess to the next cycle.
- **Output per inspection** (record inline under the candidate cluster, regardless of
  decision):

  ```
  - layer-3-inspection:
      decision: PROMOTE-AS-FINDING | DROP
      reasoning: <one paragraph>
      confidence: low | medium | high
  ```

  `PROMOTE-AS-FINDING` emits a finding using the appropriate directive
  (REUSE / EXTRACT / ABSTRACT). `DROP` records the inspection but emits no finding
  (transparency so the auditor sees what was considered).

## Findings File Format

```markdown
# Pattern Findings — Convergence
**Slug:** <slug>
**Run:** <ISO timestamp>

## Layer 1 findings
[one block per finding, IDs CF-1, CF-2, ...]

## Layer 2 findings
[one block per finding, IDs continue sequentially]

## Layer 3 inspections
[one block per inspection; PROMOTE-AS-FINDING entries also appear as findings above]
```

Each EXTRACT / REUSE / REMOVE / RELOCATE finding uses a per-directive shape (see
`references/abstract-migration.md` only for ABSTRACT shape). EXTRACT shape:

```markdown
### Finding CF-<n>: EXTRACT — <name>
- directive: EXTRACT
- evidence:
  - { file: <path>, line: <int>, snippet: <one-line> }
  - { file: <path>, line: <int>, snippet: <one-line> }
- proposed-name: <name>
- proposed-signature: <signature>
- placement: <repo-relative path or shared-util location>
- reasoning: <one paragraph>
```

## Return

```
Status: SUCCESS
Mode: convergence-scout
Slug: <slug>
Findings File: .project/cycles/<slug>/refactor-proposals/pattern-findings-convergence.md
Counts:
  Layer-1: <n>
  Layer-2: <n>
  Layer-3 inspections: <n>
  ABSTRACT candidates: <n>
  EXTRACT findings: <n>
Commit: <short-hash> | skipped | failed
```

Failure / precondition violation (write did not occur):

```
Status: ESCALATE
Mode: convergence-scout
Reason: <one-line reason>
Commit: none
```

Failure / precondition violation (write occurred but commit raised an error):

```
Status: ESCALATE
Mode: convergence-scout
Reason: <one-line reason>
Commit: failed
```
