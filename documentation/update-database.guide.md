# Update Database Guide

## What It Does

Provides a standardized 8-step workflow for modifying the Prisma schema, creating migrations, and maintaining a changelog. Ensures database changes are safe, validated, and documented for cross-agent visibility — especially important in multi-worktree environments where multiple features may share the same database.

## When It Applies

This skill is loaded automatically when a developer's phase tasks involve:
- Adding, modifying, or removing Prisma models or fields
- Changing relations, indexes, unique constraints, or enums
- Any task that references `schema.prisma` or database structure

The developer agent loads this skill when it detects database-related tasks in its phase instructions.

## What Happens

1. Reads the current schema and recent changelog entries
2. Plans changes with multi-tenancy and relation checks
3. Modifies the schema
4. Validates with `npx prisma validate` (max 2 fix attempts)
5. Creates a migration with `npx prisma migrate dev`
6. Regenerates the Prisma client
7. Updates `backend/prisma/CHANGELOG.md` with what changed and why
8. Verifies the backend build still passes

## The Changelog

The skill maintains `backend/prisma/CHANGELOG.md` — a human-readable record of every schema change. Each entry includes the date, migration name, affected models, specific changes with reasons, and any notes about breaking changes or data backfills. Agents read this to understand recent schema evolution without diffing migration SQL files.

## Multi-Worktree Safety

All worktrees share the same PostgreSQL instance. Key implications:
- A migration applied in one worktree affects the database for all worktrees
- Two feature branches creating conflicting migrations will cause problems at merge time
- The skill checks `prisma migrate status` before creating migrations and warns if unapplied migrations from other branches exist

Avoid running two features with schema changes in parallel. If unavoidable, coordinate migration names and field additions carefully.

## Related

| File | Purpose |
|------|---------|
| `.claude/skills/developer-skills/backend/update-database/SKILL.md` | Skill definition |
| `backend/prisma/schema.prisma` | Prisma schema (modified by this skill) |
| `backend/prisma/CHANGELOG.md` | Schema changelog (maintained by this skill) |
| `backend/prisma/migrations/` | Migration files (created by this skill) |
