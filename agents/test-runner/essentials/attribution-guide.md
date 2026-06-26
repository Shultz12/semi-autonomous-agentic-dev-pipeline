# Fault Attribution Guide

Preliminary classification of test failures. Code-investigator verifies and may reclassify every attribution you produce — your job is to provide the best initial assessment with evidence.

## Attribution Values

| Value | Meaning | Downstream Effect |
|-------|---------|-------------------|
| CODE_BUG | Implementation has a bug; test is correct | Code-investigator verifies → developer fixes implementation |
| TEST_BUG | Test itself is wrong; implementation may be correct | Code-investigator verifies → developer (test-writer) fixes test |
| UNCLEAR | Cannot determine with available evidence | Code-investigator resolves the ambiguity or escalates |

## Decision Tree

For each failing test, follow this sequence:

### 1. Resolve the Spec-of-Record

Every test has a **spec-of-record** — the authoritative statement of the behavior it is meant to verify. Resolve it **per test**, in this order:

- A BDD `.feature` scenario in the feature's `specs/` directory that corresponds to the failing test → that scenario is the spec-of-record.
- Otherwise, for a **bugfix reproduction test** (a test with no `.feature` whose purpose is to reproduce a reported bug) → the bug report's `## Expected Behavior` is the spec-of-record.

Then branch:

- **A spec-of-record is found** (BDD scenario or bug-report expectation) → continue to step 2.
- **No spec-of-record can be identified** — neither a matching BDD scenario nor a bug-report expectation → likely TEST_BUG (the test may be testing something not specified). Lacking a `.feature` is **not** by itself sufficient: a bugfix reproduction test whose spec-of-record is its bug report's `## Expected Behavior` is fully specified and does not fall here.

### 2. Compare Test Assertion to Spec-of-Record

Read the failing test's assertion. Does it align with what the spec-of-record specifies?

- **Assertion contradicts spec-of-record** → TEST_BUG
  - Example: spec says "should return 404", test asserts 400
- **Assertion aligns with spec-of-record** → continue to step 3
- **Cannot determine alignment** → UNCLEAR

### 3. Compare Implementation to Spec-of-Record

Read the implementation code that the test exercises. Does it implement what the spec-of-record specifies?

- **Implementation doesn't match spec-of-record** → CODE_BUG
  - Example: spec says "validate input before processing", implementation skips validation
- **Implementation matches spec-of-record but test still fails** → likely TEST_BUG (bad mock, wrong setup, incorrect import)
- **Cannot determine** → UNCLEAR

### 4. Check for Structural Test Issues

If you reach this step, look for common test problems:

- **Wrong import path** → TEST_BUG
- **Incorrect mock setup** (mock doesn't match real interface) → TEST_BUG
- **Missing test setup/teardown** → TEST_BUG
- **Stale snapshot** → TEST_BUG
- **Race condition or timing issue** → UNCLEAR (may be flaky)

## Evidence Requirements

Every attribution must include 1-2 sentences of evidence. Good evidence cites specific code:

**Good evidence (CODE_BUG):**
> Test asserts `validateInput()` throws on empty string per the spec-of-record "invalid input rejection". Implementation at `auth.service.ts:45` accepts empty string without validation.

**Good evidence (TEST_BUG):**
> Test mocks `UserRepository.findOne` to return `null`, but the mock signature uses `findById` which doesn't exist on the repository interface. The test assertion itself aligns with the spec-of-record.

**Good evidence (UNCLEAR):**
> Test expects `createdAt` to be within 1 second of `Date.now()`, but the failure shows a 2-second gap. Could be a timing issue in test setup or a bug in the timestamp assignment logic.

## When to Use UNCLEAR

Use UNCLEAR when:
- Evidence points in both directions
- The failure could be environmental (timing, order-dependent)
- The spec-of-record is ambiguous about the expected behavior
- The stack trace points to framework internals rather than application code

Do not use UNCLEAR as a default. Make a determination when the evidence supports one.
