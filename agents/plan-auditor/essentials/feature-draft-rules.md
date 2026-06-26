# Feature-Draft Rules

Extends `base-rules.md` for `Target: feature-draft` audits. The target artifact is `.project/cycles/<cycle>/plans/implementation-plan-draft.md`.

The draft is audited so that verb-noun, concern, metadata, phase-sizing, and path-grounding defects are caught and fixed at the draft layer — before `feature-final` copies the draft's task headers and metadata verbatim. A defect fixed here is fixed in one place; the same defect discovered only at the feature-final audit cannot be fixed in the final (its headers must match the draft), so it forces a return to the draft anyway. Auditing the draft removes that round-trip.

## Rule set

`base-rules.md` is the entire rule set for this target — every base rule applies to the draft:

- Verb-noun discipline (`UNDOCUMENTED_VERB`)
- One-concern discipline (`MISSING_CONCERN`, `INVALID_CONCERN`, `MULTIPLE_CONCERNS`)
- Domain-noun discipline (`GENERIC_NOUN`)
- Per-task metadata (`MISSING_TASK_METADATA`)
- Phase sizing (`PHASE_*` hard caps, mandatory boundaries, soft targets)
- Code-reference grounding (`PATH_NOT_FOUND`, `PATH_NEW_BUT_EXISTS`)

The draft carries a `## Objective` section above its first phase (authored from the SRS), so the full-audit plan-header check applies: `MISSING_OBJECTIVE` (ERROR, plan-level) when it is absent or empty.

## Deferred to the feature-final audit

These checks have no meaning on a draft and run only under `Target: feature-final`:

- **Two-pass plan check** (`MISSING_DRAFT_PLAN`, `MISSING_FINAL_PLAN`, `DRAFT_TASK_REWRITTEN`, `DRAFT_METADATA_CHANGED`) — compares draft to final; the final does not exist at draft-audit time.
- **Directive checks** (`REUSE_PATH_NOT_FOUND`, `EXTRACT_NO_CONSUMER`, `ABSTRACT_IN_FEATURE_FINAL_DISALLOWED`) — REUSE/EXTRACT/ABSTRACT annotations are added by `feature-final`; a draft carries none.

## No target-specific violations

This target adds no violation codes of its own. A draft is VALID when it has no CRITICAL or ERROR base-rule findings.
