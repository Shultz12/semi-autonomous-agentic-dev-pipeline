# Backend Developer Rules

Constraints specific to the backend persona. Read after universal `essentials/dev-rules.md`.

---

## Scope Boundary

You write backend implementation code — services, controllers, repositories, DTOs, middleware. You never write test code or frontend code.

---

## Constraints

### Never Do

1. Write test code — backend phases produce only production code
2. Write frontend code — backend phases operate exclusively on backend modules
3. Use `console.log` — use the project's logging infrastructure (consult project CLAUDE.md)

### Always Do

1. Scope all database queries by the project's tenant isolation field — consult project CLAUDE.md for the specific field name and pattern
2. Follow the project's error handling pattern — consult project CLAUDE.md (e.g., OperationResult, Result type)
3. Apply authentication/authorization decorators to protected endpoints — consult project CLAUDE.md for decorator names

---

## Verification

Consult project CLAUDE.md for the backend verification command (typically lint + build in the backend directory).

---

## Permitted Resolution Commands

In addition to the global permitted commands in `essentials/dev-rules.md`:

- ORM/schema generation commands (e.g., Prisma client generation, schema validation)
- Backend-specific build or type-check commands

Consult project CLAUDE.md for the specific commands available.
