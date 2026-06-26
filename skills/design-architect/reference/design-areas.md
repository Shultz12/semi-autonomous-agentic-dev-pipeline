# Design Areas Reference

Guidance for each design area the Design Architect covers. Use this to determine which areas apply and what questions to resolve.

---

## 1. Component Architecture

**When it applies:** Always — every feature needs at least one component defined.

**Key questions to resolve:**
- What modules/services/components are needed?
- What is each component's single responsibility?
- How do components relate to each other?

**Common patterns (consult project CLAUDE.md):**
- Each domain module follows the project's module convention (module, service, controller equivalent)
- Frontend components organized per project structure
- Shared utilities available per project conventions

**Reference files:**
- Consult project CLAUDE.md and codebase exploration for actual paths to domain modules, shared utilities, and frontend components

---

## 2. Layer Assignment

**When it applies:** Always for backend features — determines where code lives in the project's architecture layers.

**Key questions to resolve:**
- Which layer does each component belong to?
- Are dependency directions correct (higher → lower only)?
- Is anything being placed at a higher layer than necessary?

**Common patterns (consult project CLAUDE.md):**
- Consult project CLAUDE.md for architecture layer definitions and directory mappings
- Dependencies flow one direction — higher layers import lower layers, never the reverse
- Default to the domain/business logic layer — only use orchestration layers if coordinating multiple domain services

**Dependency rule:** Higher layers depend on lower layers, never the reverse. Check CLAUDE.md for the specific layer hierarchy.

---

## 3. Data Model Design

**When it applies:** When the SRS mentions entities, persistence, schema changes, or data relationships.

**Key questions to resolve:**
- What entities are needed? What are their key fields?
- What relations exist between entities?
- If the project uses multi-tenancy (check CLAUDE.md), how is data scoped?
- Are there migration considerations?

**Common patterns (consult project CLAUDE.md):**
- Schema definition via the project's ORM
- Multi-tenancy scoping per project strategy (if applicable)
- Soft deletes where audit trails matter
- Check for existing text processing utilities before creating new ones

**Reference files:**
- Consult project CLAUDE.md for ORM schema location and utility paths

---

## 4. Processing Model

**When it applies:** When the feature involves async operations, background jobs, file processing, or event-driven behavior.

**Key questions to resolve:**
- Synchronous or asynchronous processing?
- Queue-based or event-driven?
- What happens on failure? Retry strategy?
- What are the performance constraints?

**Common patterns (consult project CLAUDE.md):**
- Queue infrastructure per project (check CLAUDE.md for queue/job framework)
- Async processing for long-running operations (file processing, external API calls, etc.)
- Project error handling pattern for error propagation (check CLAUDE.md)

**Reference files:**
- Consult project CLAUDE.md for queue infrastructure and error handling pattern locations

---

## 5. Interface Contracts

**When it applies:** When two or more new components need to communicate, or new code integrates with existing services.

**Key questions to resolve:**
- What methods/events connect components?
- What DTOs carry data between them?
- What error cases exist at each boundary?
- What validation happens at interfaces?

**Common patterns (consult project CLAUDE.md):**
- DTOs for all inter-service communication
- Project-standard result/error type as return type (not exceptions)
- Validation at controller level using the project's validation library
- Type-safe interfaces in the project's shared domain types directory

**Reference files:**
- Consult project CLAUDE.md for shared interface/DTO locations and validation approach

---

## 6. Integration Approach

**When it applies:** When new code must connect to existing services, modules, or external systems.

**Key questions to resolve:**
- Which existing services does this feature call?
- Which existing services need to call this feature?
- Are there shared database tables involved?
- What import/dependency changes are needed?

**Common patterns (consult project CLAUDE.md):**
- Framework dependency injection for service integration
- Check CLAUDE.md for globally available services (no explicit imports needed)
- Module imports for cross-domain dependencies
- Avoid circular dependencies between domain modules

---

## 7. Error Handling Strategy

**When it applies:** When the feature has failure modes beyond simple validation errors.

**Key questions to resolve:**
- What errors can occur? (Network, business logic, data, external service)
- How should each error type be handled? (Retry, fallback, escalate)
- What error messages does the user see?
- What gets logged?

**Common patterns (consult project CLAUDE.md):**
- Project error handling pattern for service-level errors (check CLAUDE.md)
- Error codes as string constants
- Localized messages for user-facing responses, technical messages for logs (per project localization strategy)
- Defense-in-depth: validate at all layers

**Reference files:**
- Consult project CLAUDE.md for error handling pattern and localization strategy

---

## 8. Security Approach

**When it applies:** When the feature handles user data, authentication, authorization, or sensitive operations.

**Key questions to resolve:**
- What authentication is required?
- What authorization/RBAC is needed?
- How is data isolated per tenant (if applicable)?
- What input validation is needed?

**Common patterns (consult project CLAUDE.md):**
- Session guard on protected endpoints (check CLAUDE.md for auth decorators)
- Access control decorator for RBAC
- Resource guard for gated operations (if applicable)
- Tenant scoping per project multi-tenancy strategy
- Defense-in-depth: validate at Frontend → Controller → Business → Domain

**Reference files:**
- Consult project CLAUDE.md for auth provider, security decorators, and guard middleware

---

## 9. State Management

**When it applies:** Frontend features only — when the feature involves client-side state.

**Key questions to resolve:**
- Where does state live? (Component-local vs global)
- How does state sync with the server?
- What reactivity patterns are needed?
- What happens on stale data or network failure?

**Common patterns (consult project CLAUDE.md):**
- Frontend state management patterns per project CLAUDE.md
- Global state using the project's prescribed state management approach
- Local state at the component level
- Follow project conventions for reactivity and state containers

**Reference files:**
- Consult project CLAUDE.md for frontend state management locations and patterns
