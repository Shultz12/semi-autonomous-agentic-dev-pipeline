# Test-Plan Rules

Extends `base-rules.md` for `Target: test-plan` audits. The target artifact is a per-phase test plan at `.project/cycles/<cycle>/plans/test-plans/phase-<N>-test-plan.md`.

The test plan carries a `## Objective` (what the phase's tests verify), so the full-audit plan-header check applies: `MISSING_OBJECTIVE` (ERROR, plan-level) when it is absent or empty.

## BDD trace

Every test phase task references at least one BDD scenario by ID.

### Verification protocol

1. For each task in every test phase, look for a `Scenario:` field referencing a BDD scenario in `[feature-file]:[scenario-name]` format, or a `Scenario ID:` field referencing a stable scenario identifier.
2. Cross-check the referenced scenario against the plan's BDD source (declared in the plan's Meta section as `BDD Specs: <path>`):
   - For `Scenario: <file>:<name>` references, Glob the feature file; if found, Grep it for the scenario name.
   - For `Scenario ID: <id>` references, Grep the BDD source directory for the ID.

### Violations

- `MISSING_BDD_TRACE: Phase N, Task N.M` — task has no `Scenario:` or `Scenario ID:` field. **Severity:** ERROR. **Confidence:** HIGH.
- `BDD_SCENARIO_NOT_FOUND: Phase N, Task N.M: <reference>` — cited scenario does not resolve in the BDD source. **Severity:** ERROR. **Confidence:** HIGH (Grep result is deterministic).
- `BDD_SOURCE_UNAVAILABLE: <path>` — plan's `BDD Specs` path is missing, unreadable, or contains no `.feature` files. **Severity:** WARNING (audit cannot verify scenario resolution; surface the gap). **Confidence:** HIGH.

## Coverage scope

The test plan addresses only the implemented feature's code paths. No tests for unimplemented spec items.

### Verification protocol

1. For each task, identify the `Reference:` field (or equivalent backtick-wrapped path to the implemented code under test).
2. Run Glob against each `Reference:` path.
3. Reference paths that resolve to existing files satisfy the rule. Reference paths that resolve to nothing indicate the test targets code that has not been implemented.

### Violations

- `MISSING_TEST_REFERENCE: Phase N, Task N.M` — task has no `Reference:` field pointing to implemented code. **Severity:** ERROR. **Confidence:** HIGH.
- `TEST_TARGET_UNIMPLEMENTED: Phase N, Task N.M: <path>` — `Reference` path does not resolve at HEAD; test targets unimplemented code. **Severity:** ERROR. **Confidence:** HIGH.

## Out of scope

This rule set does NOT enforce the verb-noun discipline's `UNDOCUMENTED_VERB` check for test verbs — test-plan tasks use the same verb-noun discipline as implementation tasks (closed list in `.claude/agents/plan-architect/essentials/allowed-verbs.md` applies). The base rule covers it; no override here.

This rule set does NOT check `Verify:` fields against compilation-vs-execution semantics. That distinction is enforced at the test-execution layer (test-runner), not in the structural audit.

This rule set does NOT apply ASK-FIRST-style governance — test plans do not introduce production dependencies, so the concern does not arise.
