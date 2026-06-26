# Action: create

Applies when the dispatch carries `Mode: create`.

## Precondition

The target artifact does not exist at the target path at dispatch time. The exact path is target-specific (see `modes/targets/<target>.md`). If the target artifact exists, the action returns an error and writes nothing.

Targets layer additional preconditions on top of this one (e.g., `feature-final` requires `implementation-plan-draft.md` to exist before its own create succeeds). Failing any precondition — base or target-specific — fails the dispatch with the documented error code.

## Discipline

1. Read the source inputs declared by `modes/targets/<target>.md` under "Inputs (any action)" and "Additional inputs" (the `Mode: create` subsection).
2. Apply the writing discipline from `essentials/writing-discipline.md`, the closed verbs in `essentials/allowed-verbs.md`, and the phase-sizing rules in `essentials/phase-sizing.md`.
3. Author the target artifact from scratch at the path the target file specifies.
4. Run the target-specific create mechanic in the target file's `### When Mode: create` subsection (e.g., copy-from-draft for `feature-final`, single-pass authoring for `refactor-plan`).

## After write

Once the artifact is written, it becomes the source of truth for downstream consumers (developer, plan-auditor, orchestrator). Revisions flow through the `update` action — never through a second `create`.

## Output contract

The action does not define an output format. Each target file's "Output" section specifies the artifact's structure (verb-noun headers, per-task metadata, ABSTRACT annotations when applicable). The action ensures the precondition holds and the writing discipline is applied; structural correctness is the target's responsibility.

If a precondition fails, the response is the target-specific error code with no file write.
