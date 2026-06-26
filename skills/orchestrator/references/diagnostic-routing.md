# Diagnostic Routing Table

Determines when to invoke code-investigator before routing to developer for fixes. The orchestrator checks code-reviewer's structured return (categories, severity, finding count) against this table.

This file is designed to be human-editable. Moving a category between sections changes the pipeline behavior without agent code changes.

## Severity Tiers

Code-reviewer returns findings tagged on two independent axes: Severity × Category.
- Severity: `CRITICAL | ERROR | WARNING`
- Category: `LOGIC | VALIDATION | INTEGRATION | TYPE | SECURITY | CONVENTION`

`CRITICAL` findings always block phase progression and always route to code-investigator regardless of category.

## General Rules

- If ANY finding is at `CRITICAL` severity, route to code-investigator unconditionally.
- If ANY category in the review matches "always diagnose," route to code-investigator (even if other categories are in "direct to developer").
- If any conditional category has 3+ findings, route to code-investigator (volume override — repeated findings in a conditional category suggest a systematic pattern worth investigating, even on first failure). This override does not apply to "direct to developer" categories (CONVENTION, TYPE WARNING) — those are never worth investigating regardless of count.

## PHASE_REVIEW / ABSTRACT_MIGRATION_REVIEW Routing

### Always diagnose (route to code-investigator)

| Category | Min Severity | Rationale |
|----------|-------------|-----------|
| LOGIC | ERROR | Logic errors may indicate plan-level issues |
| SECURITY | WARNING | Security fixes must never be bandaids |
| INTEGRATION | ERROR | May indicate cross-phase dependency problems |

### Direct to developer (skip code-investigator)

| Category | Max Severity | Rationale |
|----------|-------------|-----------|
| CONVENTION | any | Always a local pattern fix |
| TYPE | WARNING | Usually a missing annotation |

### Conditional (diagnose on second failure only)

First attempt: route directly to developer. If the developer's fix fails code-review again with the same category, THEN route through code-investigator.

| Category | Min Severity | Rationale |
|----------|-------------|-----------|
| VALIDATION | ERROR | Usually local, but repeated failure suggests deeper issue |
| TYPE | ERROR | Usually local, but could indicate interface mismatch |

## TEST_REVIEW Routing

### Always diagnose

| Category | Min Severity | Rationale |
|----------|-------------|-----------|
| LOGIC | ERROR | Test logic error may indicate misunderstanding of the spec |
| INTEGRATION | ERROR | Test wiring issue may indicate wrong API surface |

### Direct to developer (test-writer)

| Category | Max Severity | Rationale |
|----------|-------------|-----------|
| CONVENTION | any | Test pattern fix (AAA, naming) |
| TYPE | WARNING | Missing type annotation in test |

### Conditional

| Category | Min Severity | Rationale |
|----------|-------------|-----------|
| VALIDATION | ERROR | Usually test assertion fix |
| TYPE | ERROR | Could indicate wrong mock type |
