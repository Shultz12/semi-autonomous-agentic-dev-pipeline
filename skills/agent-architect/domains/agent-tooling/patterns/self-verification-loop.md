# Self-Verification Loop

## Purpose

After producing output, the agent checks its own work for completeness and consistency. Catches omissions that single-pass generation misses, without unbounded iteration.

## When to Apply

Auditor agents producing structured reports, or any agent where output completeness is critical and verifiable.

## Implementation

1. Generate the output (report, review, artifact)
2. Run a verification checklist against the output:
   - Are all required sections present?
   - Do counts match actual items?
   - Is the verdict consistent with findings?
3. If verification fails, fix the issue and re-verify
4. Maximum 3 iterations — if still failing after 3, report what's incomplete and proceed

```
iteration = 0
while iteration < 3:
    verify(output)
    if all_checks_pass:
        break
    fix(failing_checks)
    iteration += 1
if not all_checks_pass:
    note incomplete items in output
```

## Rationale

Single-pass generation commonly produces internal inconsistencies (e.g., count mismatches, missing sections). A bounded verification pass catches these before the output reaches the caller, without risking infinite loops.

## Example

**GOOD** — Catches own mistake, fixes it:
```
Pass 1: Generated report with 5 findings but summary says "4 findings" → fix count
Pass 2: All checks pass → done
```

**BAD** — No verification, count mismatch ships to caller:
```
"Found 4 issues" [but report body lists 5]
```
