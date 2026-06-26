# Backend Review Criteria

Backend-specific validation. These rules supplement the universal rules in `essentials/review-rules.md`.

Read the project's CLAUDE.md before reviewing to load critical constraints and guardrails. If CLAUDE.md references separate context files for backend conventions, read the backend context file — it contains wiring verification patterns, architecture rules, and utility catalogs needed for review.

---

## What to Look For in Project Documentation

Before reviewing, locate and internalize these from the project's CLAUDE.md and backend context:

### Architecture
- Layer/module organization and dependency rules
- Where domain logic, infrastructure, and shared code live
- Controller/entry point conventions
- Dependency direction rules (which layers may import which)
- Verify modified files respect the architecture's dependency direction — violations are CRITICAL

### Error Handling Pattern
- How services return errors (Result pattern, exceptions, etc.)
- Whether exceptions are allowed in certain layers (e.g., controllers)
- Services using the wrong error return pattern is ERROR

### Security
- Authentication/authorization decorators or middleware
- Data isolation patterns (multi-tenancy, row-level security, etc.)
- Which endpoints require which guards
- Missing security decorators on protected endpoints is ERROR

### Module/Service Registration
- How services are registered (dependency injection, module system, etc.)
- How cross-module dependencies are declared (exports, providers, etc.)
- Module import rules that follow architecture layers

### Repository/Data Access Pattern
- Where data access code lives
- Mapper pattern (if any) — method names, placement
- Whether domain layers access the database directly or through abstractions
- Direct database access from forbidden layers is ERROR

### Path Aliases
- Import alias conventions for cross-layer imports
- Whether relative paths crossing boundaries are allowed
- Relative paths crossing layer boundaries when aliases exist is WARNING

### Shared Utilities Catalog
- Text processing, file operations, validation utilities
- Check these BEFORE flagging "missing utility"
- Recreating functionality that exists in shared utilities is WARNING

### Controller Conventions
- Where controllers live
- Input validation and parsing rules
- How error results are transformed to HTTP responses

### Verification Command
- The lint + build command for backend code
- Use this for Step 4 diagnostics
