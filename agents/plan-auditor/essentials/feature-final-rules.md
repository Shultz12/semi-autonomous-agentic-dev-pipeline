# Feature-Final Rules

Extends `base-rules.md` for `Target: feature-final` audits. The target artifact is `.project/cycles/<cycle>/plans/implementation-plan.md`.

## Two-pass plan check

Both files MUST exist in `.project/cycles/<cycle>/plans/`:

- `implementation-plan-draft.md`
- `implementation-plan.md`

The final differs from the draft only by ADDITIONS:

- Every task header in the draft appears verbatim in the final (same line text).
- `Acceptance`, `Concern`, and `Target file(s)` fields on existing draft tasks are unchanged.
- New phases may be inserted before, between, or after draft phases.
- REUSE annotations (e.g., an `import from <path>` line) may be inserted INSIDE a draft task body, but never on the existing lines themselves.
- EXTRACT directives may insert a new earlier phase that later phases consume.

### Verification protocol

1. Read both files.
2. For each draft task header (verb-noun line), Grep the final for the verbatim header. Absence → violation.
3. For each draft task, compare `Acceptance`, `Concern`, and `Target file(s)` field values between draft and final. Any value change → violation.

### Violations

- `MISSING_DRAFT_PLAN: <cycle>` — draft file absent. **Severity:** CRITICAL. **Confidence:** HIGH.
- `MISSING_FINAL_PLAN: <cycle>` — final file absent. **Severity:** CRITICAL. **Confidence:** HIGH.
- `DRAFT_TASK_REWRITTEN: Phase N, Task N.M` — draft task header text changed in final. **Severity:** ERROR. **Confidence:** HIGH.
- `DRAFT_METADATA_CHANGED: Phase N, Task N.M: <field>` — `Acceptance` / `Concern` / `Target file(s)` value changed between draft and final. **Severity:** ERROR. **Confidence:** HIGH.

This rule is cross-phase by construction (compares two files). It runs in `full-audit` only; `phase-audit` skips it.

## No-ABSTRACT-in-feature-final rule

`Target: feature-final` plans MUST NOT contain:

- Any phase header tagged `abstract-migration-phase`.
- Any inline `<!-- ABSTRACT directive applied... -->` annotation.

ABSTRACT directives are emitted exclusively by `Target: refactor-plan` (see `refactor-plan-rules.md`). Feature-final's directive scope is restricted to REUSE and EXTRACT only.

### Allowed exception

The `<!-- ABSTRACT-deferred: candidate identified; deferred to post-merge refactor cycle -->` marker (emitted by `plan-architect`'s `targets/feature-final.md` when it detects an ABSTRACT candidate it cannot author) is INFORMATIONAL and is NOT a violation.

Distinguish by prefix: `ABSTRACT-deferred:` (allowed) vs `ABSTRACT directive applied` (disallowed).

### Verification protocol

1. Grep the plan for `abstract-migration-phase`. Any match → violation.
2. Grep the plan for `<!-- ABSTRACT directive applied`. Any match → violation.
3. Grep the plan for `<!-- ABSTRACT-deferred:`. Matches are allowed and not reported.

### Violation

`ABSTRACT_IN_FEATURE_FINAL_DISALLOWED: Phase N` — **Severity:** ERROR. **Confidence:** HIGH.

## REUSE-directive existence check

For each REUSE directive (a line in a task body matching `import from <path>` or equivalent inline reuse annotation):

- The cited path MUST resolve to an existing file at HEAD via Glob.

### Verification protocol

1. Grep the plan for `import from \`` (or the project's reuse annotation idiom) within task bodies.
2. For each match, extract the backtick-wrapped path.
3. Run Glob against the path.

### Violation

`REUSE_PATH_NOT_FOUND: <path>` (Phase N, Task N.M) — **Severity:** ERROR. **Confidence:** HIGH.

## EXTRACT-directive sanity check

For each EXTRACT directive (a phase inserted to author a shared utility consumed by later phases):

- At least one later task in the plan must consume the extracted util (via a REUSE directive citing the extracted file, or a `Target file(s)` reference to it).

### Verification protocol

1. Identify EXTRACT phases. Heuristic: a phase whose only task creates a new shared util AND whose phase name or annotation labels it as an extraction.
2. For each EXTRACT phase, identify the `Target file(s)` path of the extracted util.
3. Grep the plan from that phase forward for the extracted path appearing as a REUSE citation or `Target file(s)` reference.

### Violation

`EXTRACT_NO_CONSUMER: Phase N` — **Severity:** WARNING. **Confidence:** MEDIUM (heuristic — verify manually; EXTRACT identification relies on pattern recognition).

## Out of scope

This rule set does NOT run or check for `find-call-sites.ts`. Call-site analysis moved to `pattern-analyst` (the post-merge scout-and-refactor flow); feature-final no longer involves it.

This rule set does NOT verify inline ABSTRACT annotations beyond the disallowance check above. ABSTRACT verification logic lives exclusively in `refactor-plan-rules.md`.
