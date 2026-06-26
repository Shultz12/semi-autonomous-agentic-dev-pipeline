---
name: update-database
description: Standardized workflow for Prisma schema modifications, migrations, and changelog maintenance. Ensures safe database changes across worktrees. Use when a phase task involves modifying the Prisma schema, creating migrations, or changing database structure.
domain: dev-tooling
model: inherit
permissionMode: default
allowed-tools: Read, Edit, Write, Bash, Glob, Grep
---

# Update Database

Safe, standardized workflow for modifying the Prisma schema and creating migrations. Maintains a changelog for cross-agent visibility.

## Completion Gate

Register the changelog as the primary output before beginning the workflow:

```bash
echo "backend/prisma/CHANGELOG.md" > /tmp/.claude-agent-output-target
```

Run this registration before Step 1 begins. The changelog is the mandatory output that ensures cross-agent visibility of what changed. The output path is communicated back to the calling agent via this registration.

## Output

This skill modifies the following files:
- `backend/prisma/schema.prisma` — the Prisma schema (modified in Step 3)
- `backend/prisma/migrations/[timestamp]_[name]/` — migration files (created in Step 5)
- `backend/prisma/CHANGELOG.md` — schema changelog (written/updated in Step 7)

## When This Skill Applies

This skill is loaded when a developer's phase tasks include any of:
- Adding, modifying, or removing Prisma models
- Adding, modifying, or removing fields on existing models
- Changing relations between models
- Adding or modifying indexes, unique constraints, or enums
- Any task that references `schema.prisma` or database structure

## Changelog

**Path:** `backend/prisma/CHANGELOG.md`

The changelog is the source of truth for what changed in the schema and why. Agents read it to understand recent schema evolution without diffing migration files.

### Format

```markdown
# Prisma Schema Changelog

## [YYYY-MM-DD] Migration: [migration-name]

**Phase:** [N] of [cycle-slug] (or "manual" if outside orchestrator)
**Models affected:** [Model1, Model2]

### Changes

- Added model `ModelName` with fields: [field list]
- Added field `fieldName` (Type) to `ModelName` — [reason]
- Modified field `fieldName` on `ModelName`: [old] -> [new] — [reason]
- Removed field `fieldName` from `ModelName` — [reason]
- Added index on `ModelName(field1, field2)` — [reason]
- Added relation `ModelName` -> `OtherModel` via `fieldName` — [reason]

### Notes

[Any additional context: breaking changes, data backfill needed, multi-tenancy scope considerations]
```

### Rules

- Prepend new entries (newest first)
- One entry per migration
- Every field change includes a reason (not just "added field X")
- Note breaking changes explicitly
- Note if data backfill is required
- If this is the first entry, create the file with the header

## Workflow

### Step 1: Read Current Schema

Read `backend/prisma/schema.prisma` to understand the current state.

If `backend/prisma/CHANGELOG.md` exists, read the most recent 2-3 entries to understand recent changes and patterns.

### Step 2: Plan Changes

Before modifying the schema:

1. List every model, field, relation, and index to add/modify/remove
2. For each change, verify:
   - **Multi-tenancy**: Does the model need `organizationId`? Does every query scope by it?
   - **Relations**: Are `@relation` annotations correct? Is `onDelete` behavior explicit?
   - **Indexes**: Are frequently-queried fields indexed? Are compound indexes needed?
   - **Defaults**: Are sensible defaults provided for new required fields on existing models?
   - **Naming**: Does the naming follow existing schema conventions (check existing models)?

3. If adding a required field to a model with existing data:
   - The field MUST have a `@default()` value, OR
   - A two-step migration is needed (add as optional, backfill, make required)
   - Report this to the orchestrator/user if uncertain

### Step 3: Modify Schema

Edit `backend/prisma/schema.prisma` with the planned changes.

### Step 4: Validate

Run validation to catch errors before creating the migration:

```
cd backend && npx prisma validate
```

If validation fails:
- Read the error message
- Fix the schema
- Re-validate
- Max 2 fix attempts, then report the error

### Step 5: Generate Migration

Create the migration with a descriptive name:

```
cd backend && npx prisma migrate dev --name [descriptive-kebab-case-name]
```

Migration naming conventions:
- `add-[model-name]` — new model
- `add-[field]-to-[model]` — new field
- `modify-[field]-on-[model]` — field change
- `add-[model]-[other-model]-relation` — new relation
- `add-[model]-indexes` — index additions

If the migration requires interactive confirmation (data loss warning), report the data-loss warning to the caller and stop. Do not auto-confirm destructive migrations.

### Step 6: Generate Client

Regenerate the Prisma client so TypeScript types reflect the new schema:

```
cd backend && npx prisma generate
```

### Step 6b: Verify Changelog Accuracy

Before writing the changelog entry, verify:
1. Every schema change made in Step 3 is accounted for in the planned entry
2. Every listed reason accurately reflects the task intent (not just "added field X")
3. Any breaking changes or data backfill requirements are identified and noted

### Step 7: Update Changelog

Append a new entry to `backend/prisma/CHANGELOG.md` following the format above. If the file doesn't exist, create it.

### Step 8: Verify Build

Run the backend build to confirm the schema changes don't break existing code:

```
cd backend && npm run build
```

If the build fails due to the schema change (e.g., removed field still referenced), report the specific errors. These are expected — the developer's phase tasks should include updating the code that references changed fields.

## Escalation Format

When the skill encounters an unresolvable condition, report to the caller using this format:

```
Status: BLOCKED | Step: [N] | Reason: [specific message]
```

Escalation conditions:
- **BLOCKED** — requires caller decision: data-loss migration warning (Step 5), validation failure after max retries (Step 4)
- **REPORT** — expected errors the caller should address: build failures due to schema changes that require code updates in other files (Step 8)

## Multi-Worktree Safety

When working in a worktree:

- **Shared database**: All worktrees connect to the same PostgreSQL instance. A migration applied in one worktree affects all others.
- **Migration conflicts**: If two feature branches create migrations, they may conflict when merged. Migration names include timestamps, so file-level conflicts are rare, but logical conflicts (both adding a field with the same name) are possible.
- **Before creating a migration**, check if other worktrees have pending migrations:
  ```
  cd backend && npx prisma migrate status
  ```
  If unapplied migrations exist that aren't from the current branch, warn the user.

## Constraints

- NEVER auto-confirm destructive migrations — the caller must explicitly decide whether data loss is acceptable; the skill lacks the business context to make this judgment, and the migration cannot be undone once applied
- NEVER modify migration files after they've been created — Prisma treats migrations as append-only; modifying them corrupts migration history and breaks `prisma migrate deploy` in other environments
- NEVER skip the validation step — running migrations without validation risks malformed SQL that can crash the database or leave it in a partial state
- Do not add new npm packages as part of this workflow — package additions require approval per the project's ASK FIRST protocol and fall outside the schema change scope
- Always scope new models with `organizationId` for multi-tenancy (unless the model is explicitly organization-independent, like system configuration)
