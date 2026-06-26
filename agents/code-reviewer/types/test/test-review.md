# Test Review Criteria

Test-specific validation for test files written by the developer (test-writer persona). These rules supplement the universal rules in `essentials/review-rules.md`.

Read the project's CLAUDE.md before reviewing to load critical constraints and guardrails. If CLAUDE.md references testing conventions or patterns, read those — they contain AAA pattern requirements, mocking guidance, and test infrastructure details.

---

## What to Look For in Project Documentation

Before reviewing, locate and internalize these from the project's CLAUDE.md and relevant context files:

### Testing Framework
- Which testing framework is used (Jest, Vitest, etc.)
- Framework-specific conventions and configuration
- Test file naming conventions (`.spec.ts`, `.test.ts`, etc.)
- Test file placement (colocated vs separate directory)

### Test Patterns
- AAA pattern (Arrange, Act, Assert) — required structure for all tests
- Mocking library and conventions (e.g., `jest-mock-extended` for interfaces)
- Whether integration tests hit real databases or use mocks
- Setup/teardown conventions

### BDD Traceability
- Whether the project uses BDD `.feature` files
- Location of BDD scenario definitions
- Expected mapping between test cases and BDD scenarios

---

## Test Structure Rules

1. **AAA pattern** — every test must follow Arrange, Act, Assert structure. Tests that mix setup, execution, and assertions are ERROR (Category: CONVENTION)
2. **One assertion concept per test** — tests that assert multiple unrelated things should be split. Multiple assertions on the same concept are acceptable. Violations are WARNING (Category: CONVENTION)
3. **Descriptive test names** — `describe` and `it`/`test` blocks must clearly state what is being tested and what the expected outcome is. Generic names like "should work" are WARNING (Category: CONVENTION)

---

## Assertion Quality

1. **Specific assertions** — `toBeDefined`, `toBeTruthy`, or `not.toBeNull` as the only assertion in a test is ERROR (Category: LOGIC). Use specific matchers: `toEqual`, `toContain`, `toHaveBeenCalledWith`, etc.
2. **Error path assertions** — tests for error cases must assert the specific error type or message, not just that "an error was thrown" (Category: LOGIC). Violations are WARNING.
3. **No hardcoded magic values** — test data should be clearly named or explained. Unexplained magic numbers/strings in assertions are WARNING (Category: CONVENTION)

---

## Mocking Rules

1. **Appropriate mocking scope** — only mock what is necessary (direct dependencies). Over-mocking (mocking internal implementation details) makes tests brittle. Over-mocking is WARNING (Category: LOGIC)
2. **No under-mocking** — external calls (APIs, database, file system) in unit tests must be mocked. Unmocked external calls are ERROR (Category: INTEGRATION)
3. **Mock verification** — mocks with `toHaveBeenCalledWith` assertions must verify meaningful arguments, not just that the mock was called. Violations are WARNING (Category: LOGIC)
4. **Consult project conventions** — the project's CLAUDE.md may specify mocking libraries or patterns. Use what the project prescribes.

---

## Determinism

1. **No timing dependencies** — tests must not rely on `setTimeout`, `Date.now()`, or wall-clock time without proper mocking/faking. Timing-dependent tests are ERROR (Category: LOGIC)
2. **No external calls** — tests must not make real HTTP requests, database calls, or file system operations (unless they are explicitly integration tests). Unmocked external calls are ERROR (Category: INTEGRATION)
3. **No test ordering dependencies** — each test must be independently runnable. Shared mutable state between tests is ERROR (Category: LOGIC)
4. **No random data without seeding** — if tests use random data, they must use a fixed seed or deterministic faker. Unseeded randomness is WARNING (Category: LOGIC)

---

## BDD Scenario Coverage

If the project uses BDD `.feature` files:

1. **Scenario traceability** — each test or test group should map to a specific BDD scenario. Tests without a clear scenario mapping are WARNING (Category: CONVENTION)
2. **Edge case coverage** — BDD scenarios that define edge cases must have corresponding tests. Missing edge case tests are ERROR (Category: LOGIC)
3. **Scenario completeness** — all scenarios in the relevant `.feature` file(s) should have at least one test. Uncovered scenarios are WARNING (Category: LOGIC)

---

## Verification Command

- The test run command for the project
- Consult the project's CLAUDE.md for the exact command
- Run the specific test files being reviewed, not the entire test suite
