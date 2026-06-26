# Action: update

Applies when the dispatch carries `Mode: update`.

## Precondition

The target artifact exists at the target path at dispatch time. The exact path is target-specific (see `modes/targets/<target>.md`). If the target artifact does not exist, the action returns an error and writes nothing.

Targets layer additional preconditions on top of this one (e.g., `feature-final` `Mode: update` requires BOTH `implementation-plan-draft.md` AND `implementation-plan.md` to exist). Failing any precondition — base or target-specific — fails the dispatch with the documented error code.

## Discipline

1. Read the existing target artifact at the canonical path.
2. Read any revised source inputs the target file lists under "Additional inputs" in the `Mode: update` subsection. A revised input is the trigger for an update — typically a spec deviation, a developer **deviation report**, an amended `approved.md`, new code paths, or test-runner failures.
3. Apply the writing discipline from `essentials/writing-discipline.md` to all changed content.
4. Run the target-specific update mechanic in the target file's `### When Mode: update` subsection.

## Diff discipline

Changes against the pre-update state are **additive** or **substitutive** — never destructive. The action MUST NOT delete content present in the existing artifact unless the target's update mechanic explicitly defines a deletion case.

- **Additive** — new phases, new tasks, new annotations, new metadata fields. Existing content unchanged.
- **Substitutive** — replacing a task body or a phase mechanic where the target's update mechanic explicitly identifies the substitution as in-scope (e.g., re-running directive analysis in `feature-final`, revising an ABSTRACT phase after amended `approved.md`).
- **Destructive** — removing phases, removing tasks, renumbering existing phases — not permitted unless the target file's update mechanic explicitly defines such removal.

## After write

The updated artifact replaces the previous version in place. Downstream consumers read the canonical path; no version suffix is appended.

If a precondition fails or the diff discipline is violated, the response is the target-specific error code with no file write.
