# Cross-Layer Coordination Standards

How backend and frontend stay consistent. This document covers only the cross-layer seams; backend-internal standards live in `backend/standards.md` and frontend-internal standards in `frontend/standards.md`. Load only when a feature touches both layers.

## API Contract Alignment

**Symmetry rule:** backend DTOs and frontend schemas must validate the same shape. A change to a backend DTO requires a corresponding frontend schema change (field names, types, required/optional, length, numeric range, regex, enum values).

- Backend is authoritative; frontend validation is for UX. Both must exist.
- Shared enums/types: define once in a shared location, or keep deliberately mirrored — document which.
- Pagination parameters and the response envelope must match the backend contract (cursor/limit, `data` + `pagination`).

## Error Code Mapping

- Every backend error code starts with `ERR_`.
- The frontend must map every `ERR_` code to a user-facing message; unmapped codes fall back to a generic localized message.
- Each code maps to a display pattern: toast (transient/user-fixable), inline (form field), error page (fatal 403/404/500), modal (requires a decision).
- English in backend logs; localized in the UI.

## Authentication Flow (end-to-end)

Session data flows: backend session (userId, role, tenantId if applicable) → API client headers → frontend session state → route guards.

**Session refresh contract:**
- Frontend detects a 401 → calls the auth provider refresh → updates session → retries the original request.
- If refresh fails → redirect to signin.
- Preserve form state across refresh.

UI role-gating mirrors backend authorization, but **UI hiding is not security** — the backend enforces every permission.

<!-- Consult project CLAUDE.md for auth provider, guard decorators, and header conventions. -->

## State Synchronization

- Optimistic updates: snapshot previous state, apply optimistically, reconcile to the server's authoritative value on success, roll back on error.
- Cache invalidation triggers: after a successful mutation, on session refresh, on tenant switch (if multi-tenant), on manual refresh.
- Prefer polling over WebSockets until real-time (<5s, multi-user) is proven necessary.

## Deployment Coordination

**Deployment order:** database migrations → backend → frontend. Migrations must succeed before dependent code deploys; the backend must support the new schema before the frontend uses it.

**Breaking-change rollout:**
- Additive (safe): new optional DTO fields, new endpoints, new error codes with fallback handling.
- Breaking: remove/rename fields, change types, change error codes → deploy backend backward-compatible first, then frontend, then remove the old path a release later.

**Rollback:** frontend rolls back independently; backend rolls back independently only if no migration was applied or the migration is reversible. Never roll back a production database without a tested backup.

## Integration Testing (full-stack)

- E2E covers full journeys: UI action → API → service → DB → response → UI update, plus error paths (validation both sides, business errors, network errors).
- Mock external integration points (payment, email, file storage) consistently across tests.
- Use factories/seed data for cross-layer test fixtures.

## Conditional: Multi-tenancy (end-to-end)

> Applies only to multi-tenant projects (check CLAUDE.md).

Tenant context flows: frontend route guard → `X-Tenant-Id` request header → backend access guard → service-layer filter → DB query constraint.

- NEVER query without a tenant-id filter.
- Backend ALWAYS extracts tenant id from the session, not from client headers/params (headers are informational only).
- On tenant switch: invalidate caches, redirect to tenant home, clear sensitive data.

## Conditional: Localization (end-to-end)

> Applies only when the project requires localization/RTL (check CLAUDE.md).

Text flows: backend normalization → storage → API returns stored form → frontend renders with correct direction (`dir`/`lang`). All user-facing messages localized; backend logs in English; error codes mapped to localized messages on the frontend.
