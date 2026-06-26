# Defense-in-Depth Validation

**Purpose**: Validate across multiple layers to catch issues early.

## When to Apply

- Architectural planning
- Security-sensitive agents
- Full-stack changes

## Implementation

```markdown
## Multi-Layer Validation

For each proposed change, validate at:

**Frontend Layer**
- UX considerations
- RTL/accessibility support
- Component patterns

**Controller Layer**
- Security validation
- Authentication/authorization
- Input sanitization

**Business Layer**
- Logic correctness
- Business rules compliance
- Edge case handling

**Data Layer**
- Data integrity
- Multi-tenancy isolation
- Query efficiency
```

## Rationale

Each layer in a system has different context and catches different categories of issues. Frontend validation catches UX and accessibility problems; controller validation catches auth and input issues; business logic validation catches rule violations; data layer validation catches integrity and isolation problems. A bug that passes through one layer — such as an unvalidated input that satisfies business rules but violates a database constraint — gets caught by the next. Single-layer validation leaves entire categories of issues undetected until production.

## Example

**GOOD** — Multi-layer validation catches a gap:
```
Change: Add organization name field to settings page.
Frontend: ✓ RTL support, input validation.
Controller: ✓ Auth check, input sanitization.
Business: ✓ Name uniqueness within tenant.
Data: ✗ Missing organization isolation — query doesn't filter by tenant ID.
→ Caught at data layer before it becomes a cross-tenant data leak.
```

**BAD** — Single-layer validation misses it:
```
Change: Add organization name field to settings page.
Frontend: ✓ RTL support, input validation.
→ "Looks good, ship it."
→ Missing auth check, no tenant isolation, SQL injection via unsanitized input.
```
