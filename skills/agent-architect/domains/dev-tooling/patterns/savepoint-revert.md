# Savepoint & Deterministic Revert

## Purpose

Enable controlled rollback when an agent's attempt at a change might fail. The agent creates a known-good checkpoint before attempting risky work, and can revert to exactly that state if the attempt fails.

## When to Apply

Apply when the agent:
- Makes changes that might need to be undone (code edits, file overwrites, artifact generation)
- Has a verification step that could fail after changes are made
- Needs to attempt multiple fixes while maintaining a clean baseline
- Produces artifacts that should be archived before replacement

**Do NOT apply** when:
- The agent is read-only (no modifications to revert)
- Changes are always additive and never need rollback (append-only logs)
- The agent's scope is small enough that manual cleanup is trivial

## Implementation

### Git-Based Savepoint (for code-modifying agents)

```markdown
### Verification Protocol

1. Create savepoint commit via the `commit-to-git` skill (`Agent: <name>`): stage the specific files, subject `wip: Phase N - [name]`
2. Run verification command (lint, build, tests)
3. If passes → proceed (commit stands)
4. If fails → record original error, then:
   - Fix attempt 1: edit files (do NOT commit), re-run verification
     - If passes: `git commit --amend --no-edit` (fold fix into savepoint)
     - If fails: revert to savepoint (`git checkout -- .` + `git clean -fd`)
   - Fix attempt 2: edit files, re-run verification
     - If passes: `git commit --amend --no-edit`
     - If fails: revert to savepoint, report failure with ORIGINAL errors
```

Key rules:
- Savepoint is created AFTER implementation, BEFORE verification
- Fresh-message commits obtain their path-scoped form and `Agent:` trailer from the `commit-to-git` skill; `git commit --amend --no-edit` reuses the existing message and does not re-add the trailer
- Fix attempts are NEVER independently committed — only folded into the savepoint
- Revert uses both `git checkout -- .` (tracked) AND `git clean -fd` (untracked) for full deterministic revert
- Original error output is preserved and reported, not the error from fix attempts

### Archive-Based Savepoint (for artifact-managing agents)

```markdown
### Archive Protocol

Before generating a new version of an artifact:
1. Check if previous version exists
2. If yes: archive it with contextual naming (e.g., `phase-N.md`, `phase-N-rebuild-M.md`)
3. Create the archive directory if needed
4. Only then generate the new version

If new version generation fails, the archived version is intact and recoverable.
```

## Rationale

Without savepoints, a failed fix attempt leaves the working directory in an undefined state — partly the original code, partly the failed fix. This makes subsequent fix attempts unreliable (they're patching a broken state, not a known-good one). Deterministic revert ensures each attempt starts from the exact same baseline, making failures reproducible and fixes independent.

## Example

**GOOD** — Developer uses savepoint with deterministic revert:
```markdown
1. Implement all tasks
2. git add + commit (savepoint)
3. Run lint → fails
4. Record original error
5. Try fix 1 → lint still fails
6. git checkout -- . && git clean -fd (back to savepoint)
7. Try fix 2 → lint passes
8. git commit --amend --no-edit (fold fix into savepoint)
```

**BAD** — Agent tries fixes without savepoint:
```markdown
1. Implement all tasks
2. Run lint → fails
3. Try fix 1 → lint still fails (working dir now has fix 1 residue)
4. Try fix 2 on top of fix 1 residue → unpredictable state
```
