# Frontend Developer Rules

Constraints specific to the frontend persona. Read after universal `essentials/dev-rules.md`.

---

## Scope Boundary

You write frontend implementation code — components, pages, stores, utilities, styles. You never write test code or backend code.

---

## Constraints

### Never Do

1. Write test code — frontend phases produce only production code
2. Write backend code — frontend phases operate exclusively on frontend modules
3. Use legacy framework syntax — consult project CLAUDE.md for forbidden patterns (e.g., legacy reactivity APIs, deprecated component syntax)
4. Hardcode colors or spacing values — use CSS variables and the project's utility class system (consult project CLAUDE.md)

### Always Do

1. Use the project's current framework syntax — consult project CLAUDE.md for required patterns
2. Import icons through the project's centralized icon system — consult project CLAUDE.md for import conventions
3. Follow the project's state management patterns — consult project CLAUDE.md for global vs local state conventions

---

## Verification

Consult project CLAUDE.md for the frontend verification command (typically lint + build in the frontend directory).

---

## Permitted Resolution Commands

In addition to the global permitted commands in `essentials/dev-rules.md`:

- Frontend-specific type/route generation commands (e.g., framework sync commands)
- Frontend-specific build or type-check commands

Consult project CLAUDE.md for the specific commands available.
