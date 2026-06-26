# Bugfix-Draft Rules

Extends `base-rules.md` for `Target: bugfix-draft` audits. The target artifact is `.project/cycles/<slug>/plans/implementation-plan-draft.md` — the first pass of the two-pass fix plan, deriving fix phases from the investigation(s) before reuse directives are added by `bugfix-final`.

The draft carries a `## Objective` (the intended-vs-actual behavior the fix restores), so the full-audit plan-header check applies: `MISSING_OBJECTIVE` (ERROR, plan-level) when it is absent or empty.

## Rule set

`base-rules.md` carries the structural load for this target — every base rule applies to the draft:

- Verb-noun discipline (`UNDOCUMENTED_VERB`)
- One-concern discipline (`MISSING_CONCERN`, `INVALID_CONCERN`, `MULTIPLE_CONCERNS`)
- Domain-noun discipline (`GENERIC_NOUN`)
- Per-task metadata (`MISSING_TASK_METADATA`)
- Phase sizing (`PHASE_*` hard caps, mandatory boundaries, soft targets)
- Code-reference grounding (`PATH_NOT_FOUND`, `PATH_NEW_BUT_EXISTS`)
- Charter grounding (`OFF_CHARTER_DEPENDENCY`, `CHARTER_MISSING`)

Unlike a reproduction plan, a draft may create or modify implementation files — there is no test-file constraint, because the failing reproduction tests already exist from Stage 1. A task's `Acceptance:` may be any verification predicate (build, lint, typecheck, or single-file test).

## Directive analysis deferred

The draft carries no REUSE / EXTRACT / ABSTRACT directives, and this target authors no directive checks — REUSE/EXTRACT grounding and the ABSTRACT-deferral rule are the `bugfix-final` audit's job (`bugfix-final-rules.md`).

## Phase ordering (advisory)

When the fix spans multiple phases — typically because the bug report bundled several distinct symptoms — the phases should be ordered so each bundled bug's fix completes within a single phase, and no phase causes an unrelated test to start failing (the reproduction-test ordering invariant the draft is authored against).

The reproduction tests live in the separate reproduction plan, so this is a best-effort structural read of the draft's phase decomposition, not a verifiable gate. It introduces **no violation code** and never affects the VALID/INVALID verdict: when the decomposition appears to split one bug's fix across phases, record a plan-level **INFO** note in the report identifying the phases involved. Do not raise an ERROR or WARNING.

## No target-specific violations

Beyond the advisory above, this target adds no violation codes of its own; any base-rules violation propagates. A draft is VALID when it has no CRITICAL or ERROR finding.

## Self-Check

Before returning, run the self-check protocol in `essentials/self-check.md` against every CRITICAL and ERROR finding.
