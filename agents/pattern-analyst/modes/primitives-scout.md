# Mode: primitives-scout

Proposes shared primitives (CREATE or ABSTRACT) needed by ≥2 accepted features. Runs
pre-feature: a "primitive" must be cited by at least two accepted SRSes to qualify as
shared. Writes findings to its own file at
`.project/cycles/<slug>/refactor-proposals/pattern-findings.md` (single findings file because
the primitives flow has one scout mode).

## Inputs

```
Mode: primitives-scout
slug: <slug>      # <DD-MM-YYYY>-primitives
```

- All accepted feature SRSes at `.project/cycles/<date>-<name>/specs/SRS.md` (Glob
  enumerated; minimum 2 required).
- `.project/knowledge/architecture.md` — for shared-utility locations.
- Inventory of existing utils via `.project/pipeline/scripts/inventory-utils.ts`. **This mode is
  the sole owner and bootstrapper of `inventory-utils.ts` in the primitives flow.**
- Call-site data via `.project/pipeline/scripts/codemods/find-call-sites.ts` when an ABSTRACT
  candidate is identified. **This mode is the sole owner and bootstrapper of
  `find-call-sites.ts` in the primitives flow.**

## Bootstrap Responsibility

- Sole bootstrapper of both `inventory-utils.ts` and `find-call-sites.ts` in the
  primitives flow (per `.claude/skills/use-pipeline-scripts/SKILL.md`'s
  single-owner-per-flow rule). The scout-and-refactor flow has separate owners; the two
  flows run in separate worktrees so each has exactly one owner.

## Workflow

1. **Register output path** — Bash: `mkdir -p .project/cycles/<slug>/refactor-proposals/ && echo ".project/cycles/<slug>/refactor-proposals/pattern-findings.md" > /tmp/.claude-agent-output-target`. The `mkdir -p` creates the cycle's `refactor-proposals/` subdirectory at scout-start — for a refactor/primitives cycle `.project/cycles/<slug>/` may not exist yet.

2. **Verify SRS preconditions** — Glob `.project/cycles/*/specs/SRS.md`. If fewer than
   2 accepted SRSes exist, escalate with `Reason: INSUFFICIENT_SRSES (<count> found, ≥2 required)`.

3. **Read context** — Read `.project/knowledge/architecture.md` for the
   `## Shared utility locations` heading.

4. **Bootstrap `inventory-utils.ts`** — Glob `.project/pipeline/scripts/inventory-utils.ts`. If
   missing, follow `.claude/skills/use-pipeline-scripts/SKILL.md`'s copy-if-missing
   protocol. Frontend prerequisite: if `.svelte-kit/tsconfig.json` is missing, run
   `pnpm --filter frontend exec svelte-kit sync` before invoking the script.

5. **Run `inventory-utils.ts`** — capture stable JSON output of existing utilities at the
   architecture-declared paths.

6. **Read all accepted SRSes** — for each enumerated SRS file, Read it and identify
   primitive requirements (validators, formatters, guards, repository helpers, etc.).
   Cross-reference across SRSes to identify primitives needed by ≥2 features.

7. **For each candidate primitive, apply the decision tree:**

   | Inventory result | Action |
   |---|---|
   | Existing util satisfies the SRS need exactly | No action — the existing util IS the answer; cite it as evidence the need is met (optional documentation finding) |
   | Existing util is a narrower variant (subset of needed parameters/cases) | Treat as **ABSTRACT candidate**. Proceed to step 8 |
   | No util exists | Emit a **CREATE** finding (no ABSTRACT evaluation, no `find-call-sites.ts` run) |

8. **ABSTRACT candidate evaluation** — for each ABSTRACT candidate:
   1. Read `.claude/agents/pattern-analyst/references/abstract-migration.md`
      (on-demand; not preloaded). Apply the hard gates + scoring axes.
   2. Bootstrap `find-call-sites.ts` per `.claude/skills/use-pipeline-scripts/SKILL.md`
      if the project copy is missing.
   3. Verify frontend prerequisite (as in step 4).
   4. Run `find-call-sites.ts --function <source-function> --source <source-module-path>
      --tsconfig <appropriate-tsconfig>` for each tsconfig the function is callable
      from. Capture JSON output.
   5. Evaluate the candidate against the matrix.
   6. Emit the finding using the structured ABSTRACT finding contract from
      `references/abstract-migration.md`. **The `srs-citations` field is REQUIRED on
      `verdict: APPROVE` ABSTRACT findings from this mode** with ≥2 entries (one per
      citing SRS); minimal subset on `verdict: REJECT`.
   7. If `verdict: REJECT`, fall back to a **CREATE** finding for a separate util with a
      different name (avoids signature ambiguity with the existing narrow variant). Both
      findings remain in the file for transparency.

9. **Run disconfirmation pass.** For each candidate finding produced in steps 7-8,
   consider a counter-argument and confirm the proposed directive is the least-invasive
   adequate response (REUSE before EXTRACT before ABSTRACT). Drop any finding that does
   not survive the counter-argument. Run this pass AFTER classification and BEFORE
   writing — findings dropped here never reach the auditor.

10. **Normalize target files to a clean starting state.** Determine the file set this
    invocation will write:

    - Always: `.project/cycles/<slug>/refactor-proposals/pattern-findings.md`.
    - When `inventory-utils.ts` was bootstrapped (copy-if-missing) this invocation: also
      `.project/pipeline/scripts/inventory-utils.ts`.
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
    writing the findings file. A bootstrap path is in the file set only when the copy
    actually fired (project copy was missing); when the project copy already existed at
    invocation start, the bootstrap was a no-op and the path is not in the file set.

11. **Write findings file** — write
    `.project/cycles/<slug>/refactor-proposals/pattern-findings.md` fresh. IDs sequential
    starting from `PF-1`.

12. **Commit the artifacts.** Read `.claude/skills/commit-to-git/SKILL.md` and follow
    it to commit every path written this invocation in one path-scoped commit. Pass:

    - `Agent: pattern-analyst`
    - `Subject: refactor(<slug>): primitives findings`
    - `Path:` every path written by this invocation. The set is:
      - Always: `.project/cycles/<slug>/refactor-proposals/pattern-findings.md`.
      - When `inventory-utils.ts` was bootstrapped this invocation: also
        `.project/pipeline/scripts/inventory-utils.ts`.
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

## Citation Discipline (Mandatory)

Every CREATE finding MUST cite ≥2 accepted SRSes by file path. Speculative roadmap
entries do NOT count as evidence (they live outside `.project/cycles/`).
`pattern-analyst-auditor` enforces this rule and will reject findings that fail it.

## Findings File Format

```markdown
# Pattern Findings — Primitives
**Slug:** <slug>
**Run:** <ISO timestamp>

## Findings
[one block per finding, IDs PF-1, PF-2, ...]
```

CREATE finding shape:

```markdown
### Finding PF-<n>: CREATE — <PrimitiveName>
- directive: CREATE
- evidence:
  - { feature-slug: <slug>, path: .project/cycles/<cycle>/specs/SRS.md, requirement: <one-line> }
  - { feature-slug: <slug>, path: .project/cycles/<cycle>/specs/SRS.md, requirement: <one-line> }
  - { inline-occurrences: <count>, paths: [<path>, <path>] }   # optional: existing inline implementations
- invariants:
  - <invariant>
- signature: <TypeScript signature>
- placement: <repo-relative path under .project/knowledge/<type>/`## Shared utility locations`>
- contract-tests:
  - <test description>
- dependencies:
  - <dep or "none">
```

ABSTRACT findings emitted from this mode use the structured ABSTRACT finding contract
from `references/abstract-migration.md` — with the additional requirement that the
`srs-citations` field is REQUIRED for `verdict: APPROVE` findings (≥2 entries).

## Return

```
Status: SUCCESS
Mode: primitives-scout
Slug: <slug>
Findings File: .project/cycles/<slug>/refactor-proposals/pattern-findings.md
Counts:
  CREATE findings: <n>
  ABSTRACT candidates: <n>
  SRSes considered: <n>
Commit: <short-hash> | skipped | failed
```

Failure / precondition violation (write did not occur):

```
Status: ESCALATE
Mode: primitives-scout
Reason: <one-line reason>
Commit: none
```

Failure / precondition violation (write occurred but commit raised an error):

```
Status: ESCALATE
Mode: primitives-scout
Reason: <one-line reason>
Commit: failed
```
