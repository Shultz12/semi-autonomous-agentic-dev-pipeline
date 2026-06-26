# Bugfix-Reproduction Rules

Extends `base-rules.md` for `Target: bugfix-reproduction` audits. The target artifact is `.project/cycles/<slug>/plans/reproduction-plan.md` — the single-pass Stage 1 plan whose tasks produce reproduction tests that compile cleanly and fail at runtime (RED) before any fix is planned.

The reproduction plan carries a `## Objective` (the bug it reproduces), so the full-audit plan-header check applies: `MISSING_OBJECTIVE` (ERROR, plan-level) when it is absent or empty.

## Bug-Expectation present

Every task carries a `Bug-Expectation:` field — the bug report's `## Expected Behavior` content, verbatim — naming the behavior the reproduction test asserts. It is the reproduction analogue of the `Scenario:` field on `test-plan` tasks: the per-task assertion contract for a flow with no BDD scenarios.

**Violation:** `MISSING_BUG_EXPECTATION: Phase N, Task N.M` — the field is absent or its value is empty. **Severity:** ERROR. **Confidence:** HIGH.

## Test-only tasks

A reproduction plan produces tests and nothing else. Every task targets a test file and is tagged `Concern: test`; the affected implementation file appears only as the subject under test, never as a file the plan creates or modifies.

### Verification protocol

1. For each task, inspect `Target file(s):` — every listed path is a test file (matches the project's test-file convention, e.g. `*.test.*`, `*.spec.*`, or a `__tests__/` path).
2. For each task, confirm `Concern:` is `test`.

**Violation:** `NON_TEST_TARGET_IN_REPRODUCTION_PLAN: Phase N, Task N.M` — a task names a non-test (implementation) target file, or carries a `Concern:` other than `test`. **Severity:** ERROR. **Confidence:** HIGH for the concern axis; MEDIUM when the test-file determination relies on a path heuristic (verify manually).

## Compile-clean acceptance, not runtime pass

A reproduction test is expected to FAIL at runtime until the fix lands, so its `Acceptance:` predicate verifies the test *compiles and lints clean* (a single-file typecheck/lint), never that the test passes. An `Acceptance:` asserting the test passes would make the reproduction plan un-auditable against a known-RED test.

**Violation:** `RUNTIME_VERIFY_IN_REPRODUCTION_TASK: Phase N, Task N.M` — the task's `Acceptance:` is a runtime test execution (asserts the test passes) rather than a single-file typecheck/lint predicate. **Severity:** ERROR. **Confidence:** MEDIUM (heuristic — the compile-vs-execute distinction is read from the acceptance wording; verify manually).

## Self-Check

Before returning, run the self-check protocol in `essentials/self-check.md` against every CRITICAL and ERROR finding.
