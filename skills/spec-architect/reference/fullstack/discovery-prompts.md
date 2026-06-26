# Cross-Layer Coordination Discovery Prompts

This library covers the coordination seams that emerge when a feature spans both backend and frontend. It does NOT repeat backend-internal or frontend-internal topics — those come from `backend/discovery-prompts.md` and `frontend/discovery-prompts.md`. Load this library only for the coordination topics, and only when the feature touches both layers.

## API Contract Alignment

### DTO / Schema Symmetry
- Do frontend validation schemas validate the same shape as backend DTOs? (field names, types, required/optional)
- Are validation rules identical on both sides? (string length, numeric min/max, regex, enum values)
- Which side validates first, and why? (frontend for UX, backend for security — backend is authoritative)
- Where do shared types/enums live? (shared types directory vs deliberately mirrored per layer)

### Request/Response Agreement
- Does the frontend's expected response shape match what the backend returns on success and on error?
- Do pagination parameters agree? (cursor/limit names, default and max page size, response envelope)
- Is API versioning coordinated for any breaking shape change?

## Error Mapping
- For every backend error code (`ERR_*`), is there a user-facing message on the frontend?
- How is each error displayed? Toast (transient, user-fixable) / Inline (form field) / Error page (fatal 403/404/500) / Modal (needs a decision)?
- Is there a fallback message for unknown codes?
- Backend logs stay English; UI messages localized per project — confirmed?

## Auth Flow (end-to-end)
- Which session data flows from backend session to frontend state? (user id, role, tenant id if applicable, custom claims)
- How does the UI handle session expiration? (detect 401 → refresh → retry original request → redirect to signin on refresh failure)
- Is form state preserved across a session refresh?
- Which role-based UI states correspond to which backend authorization rules? (UI hiding is not security — backend enforces)

## State Synchronization
- Should the UI update optimistically before the backend confirms? For which actions, and what is the rollback on error?
- Does the backend return the authoritative value the frontend reconciles to after a mutation?
- When a backend mutation succeeds, which frontend caches must be invalidated? (after mutation, on session refresh, on tenant switch)
- Real-time need: polling vs WebSocket? (prefer polling until WebSockets are proven necessary)

## E2E Testing (full-stack)
- What are the happy-path journeys spanning UI → API → service → DB → UI?
- What are the error-path journeys? (validation both sides, business errors, network errors)
- What integration points are mocked, and how? (payment gateway, email, file storage)
- What cross-layer test data is needed? (users with roles, entities in various states)

## Deployment Coordination
- Does the feature require database migrations? Are they backward compatible (additive/nullable)?
- Deployment order: migrations → backend → frontend — any deviation?
- For breaking API changes, what is the rollout? (deploy backend backward-compatible → deploy frontend on new API → remove old path a release later)
- Can frontend and backend roll back independently? Is the migration reversible?
- Should the feature sit behind a feature flag?

## Conditional: Multi-tenancy (end-to-end)
**Ask only if the project uses multi-tenancy (check CLAUDE.md).**
- Where is tenant context enforced across the flow? (frontend guard → request header → backend guard → service filter → DB constraint)
- Backend extracts tenant id from session (not client params); frontend sends it for context only — confirmed?
- On tenant switch mid-session: invalidate caches, redirect, clear sensitive state?

## Conditional: Localization (end-to-end)
**Ask only if the project requires localization/RTL (check CLAUDE.md).**
- Backend normalization → storage → API returns stored form → frontend renders with correct direction — traced?
- Are all user-facing error messages localized while backend logs stay English?
- Are inputs configured for the target locale (dir/lang, character validation)?
