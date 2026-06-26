# Review Rules (Universal)

Rules for ALL code-reviewer personas. Read this file before every review.

Also read the project's CLAUDE.md for project-specific conventions that supplement these universal rules.

---

## Reviewer Posture

Apply these rules like an adversarial reviewer: strict, by-the-book, and actively hunting for violations rather than rationalizing code into compliance. Default to doubt. If a rule could plausibly apply and you have not verified the file against it, check it. Borderline findings get surfaced, not absorbed on the author's behalf. Rigor here means every loaded rule gets checked against every modified file — it does not mean inventing issues the tools cannot prove, and it does not mean inflating severities above what the rule files specify.

---

## TypeScript Strict Mode

1. **No `any` types** — search for `any` in modified files; every instance is an ERROR (Category: TYPE)
2. **Explicit return types** — all functions must have explicit return type annotations (Category: TYPE)
3. **Unused variables** — must be prefixed with `_`; unprefixed unused vars are an ERROR (Category: CONVENTION)

---

## Code Style Compliance

1. **Run lint** — lint must pass cleanly; failures are CRITICAL (Category: CONVENTION)
2. **Run build** — build must pass cleanly; failures are CRITICAL (Category: INTEGRATION)
3. **No improper logging** — use the project's logging infrastructure (consult project CLAUDE.md); violations are ERROR (Category: CONVENTION)

---

## Data Isolation Enforcement

If the project's CLAUDE.md defines data isolation rules (multi-tenancy, row-level security, org scoping, etc.):

1. Search modified files for database queries that may be missing required scoping
2. Verify each query includes the required isolation field in its filter/where clause (unless the operation is explicitly system-level)
3. Missing data isolation scoping is CRITICAL (Category: SECURITY)

---

## Pattern Consistency

When reviewing new code:

1. Read 1-2 existing files in the same directory/module as each modified file
2. Compare structure, naming conventions, and patterns (e.g., service method signatures, controller decorator usage, component structure)
3. Flag deviations from established patterns as WARNING (Category: CONVENTION) — include what the pattern is and where the sibling file demonstrates it

---

## Import Hygiene

1. **Path aliases** — if the project defines import aliases (consult project CLAUDE.md), verify they are used instead of relative paths crossing boundaries (Category: CONVENTION)
2. **No circular dependencies** — imports must not create circular reference chains (Category: INTEGRATION)
3. **No unused imports** — verified by lint, but flag if lint misses them (Category: CONVENTION)

---

## Error Handling

Consult the project's CLAUDE.md for the error handling pattern (Result type, exceptions, etc.):

1. **Services** must follow the project's prescribed error return pattern; violations are ERROR (Category: LOGIC)
2. **Controllers/entry points** may use the framework's standard error mechanism
3. **Frontend** uses try/catch at API boundaries only — not deep in component logic (Category: LOGIC)

---

## Language Convention

Consult the project's CLAUDE.md for language conventions (if any). If the project defines different languages for different contexts (e.g., one language for code/logs, another for user-facing messages), violations are WARNING (Category: CONVENTION).

---

## Defense-in-Depth

Verify validation exists at appropriate layers:

1. Frontend: input validation before API call
2. Controller: parameter validation, auth checks
3. Business logic: domain rule enforcement
4. Missing validation at a layer is WARNING (Category: VALIDATION) (unless the layer doesn't apply to the change)

---

## No Over-Engineering

LLM-written code over-engineers by default. Actively hunt for complexity that no requirement pulled in — the test is "does a present, stated need force this, or was it added in anticipation?" All findings here are **WARNING (Category: CONVENTION)** unless noted: surface and explain them with the simpler alternative; do not inflate severity, and do not block on a judgment call. Flag, with the concrete signal cited:

1. **Speculative structure (YAGNI)** — config options, parameters, hooks, generic handlers, interfaces, or branches with no current caller, single fixed value, or unreachable path. A parameter passed exactly one value at its only call site, or a `switch`/`if` arm nothing reaches, is the tell.
2. **Premature abstraction (Rule of Three)** — a new shared helper, base class, or generic wrapper introduced for **fewer than three** real call sites. With one or two consumers, inlining is simpler; flag the abstraction and name the consumers you found.
3. **Single-use indirection** — wrappers, factories, adapters, or layers that wrap exactly one operation or have one implementation. Direct calls are simpler.
4. **KISS violations** — clever indirection where straightforward control flow would do; deep nesting, needless dynamic dispatch, or metaprogramming for a fixed, known case.
5. **DRY** — code duplicating an existing shared utility (check shared dirs before assuming new). DRY targets duplication of *existing* code; it does not justify the premature abstraction caught by #2.
6. **SRP** — a function mixing concerns (e.g., validation + persistence + notification).
7. **No Technical Debt** — temporary-fix markers (`TODO`, `HACK`, `FIXME`, `XXX`, `temporary`, `for now`) added in this change, unless they reference a tracking ticket or open question. A marker added with no context is an implicit promise of future cleanup that nothing enforces.

Simplicity is also a security and maintainability lever: every speculative branch is untested attack surface and a place for defects to hide. The simpler equivalent is usually both safer and more readable.

---

## Integration Context

These checks apply to PHASE_REVIEW and CYCLE_REVIEW modes.

### 1. One-Hop Dependency Trace

For each modified file:
1. Grep for files that **import** the modified file (downstream dependents)
2. Grep for files that the modified file **imports** (upstream dependencies)
3. Read those files to verify signatures, types, and contracts still match after the changes
4. **Boundary:** One hop only — do not trace transitively. If a modified file imports `ServiceA`, check `ServiceA` but do not follow `ServiceA`'s imports.
5. Mismatched signatures, missing parameters, or broken type contracts are ERROR (Category: INTEGRATION)

### 2. Utility Duplication Search

1. For each newly created function or utility in the modified files, search the project's shared utilities directories (consult project CLAUDE.md for locations) for similar function names
2. Flag recreated functionality that already exists in shared directories as WARNING (Category: CONVENTION)
3. Include the path to the existing utility in the finding so the developer can replace the duplication
