# Infrastructure Review Criteria

Infrastructure-specific validation for database schemas, containerization, migrations, and data mappers. These rules supplement the universal rules in `essentials/review-rules.md`.

Read the project's CLAUDE.md before reviewing to load critical constraints and guardrails. If CLAUDE.md references separate context files for backend or infrastructure conventions, read the relevant context file — it contains schema conventions, wiring patterns, and migration rules needed for review.

---

## What to Look For in Project Documentation

Before reviewing, locate and internalize these from the project's CLAUDE.md and infrastructure/backend context:

### Schema/ORM Conventions
- Model/table naming conventions (PascalCase, snake_case, etc.)
- Field naming conventions
- Enum value conventions
- Naming violations are WARNING

### Timestamps
- Whether models require timestamp fields (createdAt, updatedAt, etc.)
- Missing timestamps on new models (when required) is ERROR

### Relations
- Foreign key naming conventions
- Whether explicit join tables are required for many-to-many
- Foreign key fields must follow the project's naming convention

### Data Mapper Pattern
- Where mappers live (if the project uses them)
- Required method signatures (toDomain, toPersistence, etc.)
- One mapper per domain entity
- Missing mapper for a model that has domain representation is WARNING

### Infrastructure Layer Placement
- Where schema files, migrations, mappers, database modules, and container configs live
- Infrastructure code placed outside the designated layer is ERROR

### Migration Conventions
- Migration naming conventions
- Generic migration names are WARNING

### Container/Environment Config
- Verify container config changes don't break existing service ports
- Verify environment variables referenced in code exist in dev config
- New services must document their port

### Verification Command
- The schema validation + build command for infrastructure code
- Use this for Step 4 diagnostics
