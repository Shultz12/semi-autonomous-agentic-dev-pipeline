# Backend Feature Discovery Prompts

This document contains core discovery prompts organized by topic area. These serve as starting points that the AI expands dynamically based on user responses. The goal is to gather all information needed to generate a complete, standards-compliant backend specification.

## How to Use This Document

1. **Start with Core Identity** to establish basic feature context
2. **Proceed through topic areas** relevant to the feature type
3. **Expand dynamically** - ask follow-up questions based on user responses
4. **Skip irrelevant sections** - not every feature needs every topic
5. **Reference standards** - validate completeness against `standards.md` checklist

---

## Core Identity

**Purpose**: Establish fundamental feature characteristics before diving into details.

- What is the name of this feature or module?
- What business goal or user problem does this feature solve?
- Is this a new module or an extension of an existing one? If extending, which module?
- Which architecture layer(s) will this feature primarily live in? (consult project CLAUDE.md for layer conventions)
- Are there any existing features or modules this is similar to that we should reference?
- What is the priority/urgency of this feature? (Critical, High, Medium, Low)

**Dynamic Expansion Examples**:
- If new module: "What should the module be named? Follow project naming conventions from CLAUDE.md."
- If extension: "Which specific service(s) will be modified?"
- If multiple layers: "Describe the responsibility split between layers."

---

## Data & Storage

**Purpose**: Define data models, database schema changes, relationships, and migration strategy.

- What data needs to be stored for this feature?
- Are new database models required, or modifications to existing models? (consult codebase exploration results for the ORM and schema location)
- What are the field names, types, and constraints? (e.g., required vs optional, max length, enum values)
- What relationships exist with other models? (one-to-one, one-to-many, many-to-many)
- What indexes are needed for query performance?
- Is soft delete required (`deletedAt` field), or hard delete acceptable?
- Are there any data migrations needed? (e.g., backfill existing records, transform data)
- Is audit logging required for this data? (track who created/updated records and when)

**Conditional — Data Isolation (if project uses multi-tenancy):**
- Should this data be scoped to a tenant? If yes, add tenant identifier field.
- Consider composite indexes for tenant-scoped queries.

**Dynamic Expansion Examples**:
- If relationships exist: "What are the cascade rules (Cascade, SetNull, Restrict)?"
- If composite indexes: "What query patterns will be most common?"
- If data migration: "Is this a zero-downtime migration? What's the rollback strategy?"
- If audit logging: "What fields should be tracked? Should changes be stored as JSON diff?"

**Reference**:
- Schema and migration locations: consult codebase exploration results for actual paths

---

## API Design

**Purpose**: Define HTTP endpoints, request/response structures, validation rules, and OpenAPI documentation.

- What HTTP endpoints are needed for this feature? (List method + path, e.g., GET /api/v1/users/:id)
- For each endpoint:
  - What is the HTTP method? (GET, POST, PATCH, PUT, DELETE)
  - What are the path parameters? (e.g., `:userId`)
  - What are the query parameters? (e.g., pagination, filtering, sorting)
  - What is the request body structure (DTO)? Include field types and validation rules.
  - What is the response body structure? Include success and error responses.
  - What authentication/authorization is required? (Public, authenticated, role-specific)
- Does this endpoint need pagination? If yes, cursor-based or special requirements?
- Are there filtering or sorting capabilities? What fields can users filter/sort by?
- What validation rules apply to inputs? (Required fields, max length, regex patterns, custom validators)
- Should this endpoint support bulk operations? (e.g., batch create, bulk update)
- Are there any special headers required? (e.g., Idempotency-Key, Content-Type)
- Are WebSockets or real-time updates needed, or is REST sufficient?

**Dynamic Expansion Examples**:
- If pagination: "What is the default page size? Maximum page size? Should total count be included (expensive)?"
- If filtering: "What filter operators are supported? (equals, contains, greaterThan, lessThan, in, between)"
- If validation: "Are there project-specific text validations needed? Check for existing validation utilities in the codebase."
- If bulk operations: "What is the maximum batch size? How are partial failures handled?"
- If WebSockets: "What events should be emitted? Is message ordering guaranteed? Reconnection strategy?"

**Reference**:
- Validation library: consult project CLAUDE.md for the validation approach
- Existing utilities: check codebase exploration results for reusable validation and text processing helpers

---

## Business Logic

**Purpose**: Define core business rules, invariants, workflows, error scenarios, and domain-specific requirements.

- What are the core business rules for this feature? (e.g., "Users can only delete their own comments unless they're an admin")
- Are there any invariants that must always be true? (e.g., "Account balance cannot be negative")
- What are the edge cases or error scenarios? (e.g., duplicate entries, insufficient resources, file too large)
- For each error scenario:
  - What error code should be returned? (Use a consistent format, e.g., `ERR_DOMAIN_XXX`)
  - What is the user-facing error message? (localized if project requires localization)
  - How should the system recover? (Retry, rollback, notify user, log and continue)
- Are there any multi-step workflows or state machines? (e.g., UPLOADED → PROCESSING → COMPLETED → FAILED)
- Are there any calculations or transformations? (e.g., extract structured data from text, calculate totals)
- What are the success criteria? How do we know this feature is working correctly?

**Conditional — Data Isolation (if project uses multi-tenancy):**
- How is this feature scoped to tenants? Should users only see data from their own tenant?
- Should admin users bypass tenant scoping? How is this logged?

**Dynamic Expansion Examples**:
- If workflows: "What triggers state transitions? Can states be skipped? Are transitions reversible?"
- If calculations: "Are there existing utilities for this? Check codebase exploration results. Should results be cached?"
- If invariants: "Should this be enforced at database level (CHECK constraint) or application level?"

**Reference**:
- Error handling patterns: check codebase exploration results for existing error/result patterns
- Text utilities: check for existing text processing utilities in the codebase

---

## Integration

**Purpose**: Identify existing utilities to reuse, external services to integrate, events to emit, and caching strategy.

- What existing utilities can be reused for this feature? (consult codebase exploration results)
  - Text processing utilities?
  - File operation utilities?
  - Error handling / result patterns?
- Does this feature interact with external services? (e.g., email, SMS, payment gateway, cloud storage)
- For each external service:
  - What is the integration pattern? (REST API, SDK, webhook)
  - What error handling is needed? (Retry with exponential backoff, circuit breaker, fallback)
  - Should calls be synchronous or asynchronous (background job)?
- Should this feature emit events for other modules to consume? (e.g., UserCreated, OrderCompleted)
- Should this feature cache data? If yes:
  - What data should be cached?
  - What is the caching strategy? (cache-aside, write-through)
  - What is the TTL? (1-5 min for real-time, 15-60 min for semi-static, 1-24 hours for static)
  - What is the cache key format?
  - When should cache be invalidated?
- Are there any background jobs or async processing?

**Dynamic Expansion Examples**:
- If external service: "What happens if the service is down? Retry count? Timeout? Should we queue for later?"
- If events: "What event payload structure? Who are the subscribers? Synchronous or asynchronous delivery?"
- If caching: "What is the expected cache hit rate? Should we warm cache on startup? How to prevent cache stampede?"
- If background jobs: "What queue should be used? Priority levels? Retry strategy? Dead letter queue handling?"

**Reference**:
- Existing utilities: consult codebase exploration results for reusable helpers and infrastructure modules
- Cache and queue infrastructure: check project structure for caching and queue modules

---

## Security

**Purpose**: Define authentication, authorization, rate limiting, input sanitization, and sensitive data handling.

- What is the authentication level required? (Public, authenticated user, specific role, super-admin)
- What role-based access control (RBAC) is needed?
  - Which roles can access this feature? (consult project CLAUDE.md for role definitions)
  - What operations can each role perform? (Read, Create, Update, Delete)
  - Are there fine-grained permissions beyond role? (e.g., "can only edit own records")
- Does this feature need organization/tenant-level access control? (if applicable per project)
- Does this feature consume metered resources? (e.g., credits, API quota)
- Are there rate limiting requirements?
  - What is the rate limit? (e.g., 10 requests/minute per user, 100 requests/hour per IP)
  - What should happen when limit exceeded? (Return 429, queue request, notify user)
- Does this feature accept user input? If yes:
  - What validation is required? (per project validation library)
  - Are there any special sanitization needs? (HTML sanitization, text normalization, SQL injection prevention)
  - What is the maximum input size? (file upload limits, request body size)
- Does this feature handle sensitive data? (passwords, tokens, credit cards, personal information)
- If sensitive data:
  - Should it be encrypted at rest?
  - Should it be redacted from logs?
  - Should it be transmitted over HTTPS only?
  - Are there any compliance requirements? (GDPR, PCI-DSS)

**Dynamic Expansion Examples**:
- If RBAC: "Create a permission matrix: Resource × Role → Allowed Operations (CRUD)."
- If rate limiting: "Should rate limits be per user, per tenant, or per IP? Different limits for different roles?"
- If file uploads: "What file types are allowed? Max file size? Virus scanning required? Store in object storage or local filesystem?"
- If sensitive data: "What is the data retention policy? When should data be deleted? Hard delete or soft delete?"

**Reference**:
- Auth decorators and guards: consult codebase exploration results for auth patterns
- Validation: consult project CLAUDE.md for the validation library

---

## Quality

**Purpose**: Define edge cases, performance targets, test coverage, and monitoring requirements.

- What are the edge cases to test?
  - Boundary conditions (empty input, max length, null values)
  - Concurrent access (race conditions, deadlocks)
  - Error scenarios (network failure, timeout, invalid input)
  - Data isolation (cross-tenant access attempts, if applicable)
- What are the performance targets?
  - Response time: p50 < 100ms, p95 < 500ms, p99 < 1s (CRUD operations)
  - Response time: p50 < 500ms, p95 < 2s, p99 < 5s (processing operations)
  - Throughput: requests per second (RPS) expected
  - Database query count: N+1 prevention, batch operations
  - Cache hit rate: target 80%+ for cached data
- What test coverage is required?
  - Overall: 80% line coverage
  - Business logic: 95% coverage
  - Critical paths: 100% coverage (auth, payment, data processing)
- What types of tests are needed?
  - Unit tests: Service methods in isolation (mock dependencies)
  - Integration tests: Multiple components together (real database)
  - E2E tests: Full user flows via HTTP (controllers → services → database)
  - Performance tests: Load testing, stress testing (if high traffic expected)
- What monitoring and alerting is needed?
  - Metrics to track: error rate, response time, throughput, queue depth, cache hit rate
  - Alerting thresholds: error rate > 1%, p95 > 500ms, queue depth > 100
  - Dashboards: What visualizations are helpful? (time series, histograms, heat maps)
- Are there any logging requirements?
  - What should be logged? (user actions, errors, performance metrics)
  - What log level? (ERROR for 5xx, WARN for recoverable issues, INFO for business events, DEBUG for diagnostics)
  - Should PII be redacted? (always yes for production)

**Dynamic Expansion Examples**:
- If performance critical: "Should this use database read replicas? Caching? CDN for static assets?"
- If high traffic: "Should we implement circuit breaker? Rate limiting? Queue deferral?"
- If complex testing: "Use the project's mocking library for type-safe mocking. No skipped tests allowed."
- If monitoring: "What monitoring tools does the project use? What SLA/SLO targets?"

**Reference**:
- Testing patterns: consult codebase exploration results for test directory structure and patterns
- Logging: check for existing logging infrastructure in the project

---

## Additional Context

**Purpose**: Capture any additional information not covered by other sections.

- Are there any constraints or limitations we should be aware of? (technical debt, legacy systems, third-party dependencies)
- Are there any compliance or regulatory requirements? (GDPR, HIPAA, PCI-DSS, accessibility)
- Are there any deployment considerations? (zero-downtime migration, feature flags, gradual rollout)
- Are there any documentation needs? (OpenAPI spec, API guide, integration guide, runbook)
- Are there any dependencies on other teams or features? (blocking issues, coordination needed)
- What is the timeline or deadline for this feature?
- Are there any known risks or unknowns that need investigation?

**Dynamic Expansion Examples**:
- If compliance: "What specific regulations apply? What documentation is required? Audit trail needed?"
- If deployment: "Should this use feature flags? Percentage rollout (canary)? A/B testing?"
- If dependencies: "What is the dependency graph? Can we parallelize development? What are the blockers?"

---

## Discovery Flow Recommendations

### For Small Features (Single Domain Service)
1. Core Identity
2. Data & Storage (if applicable)
3. API Design
4. Business Logic
5. Security
6. Quality (simplified)

### For Medium Features (New Domain Module)
1. Core Identity
2. Data & Storage
3. API Design
4. Business Logic
5. Integration (check existing utilities)
6. Security
7. Quality

### For Large Features (Cross-Domain Orchestration)
1. Core Identity
2. Data & Storage (multiple models)
3. API Design (multiple endpoints)
4. Business Logic (workflows, state machines)
5. Integration (external services, events, caching, background jobs)
6. Security (complex RBAC, sensitive data)
7. Quality (performance targets, comprehensive testing, monitoring)
8. Additional Context (compliance, deployment strategy)

---

## Prompt Expansion Strategies

### Follow-Up Question Patterns
- **Clarification**: "Can you elaborate on [topic]? What does [term] mean in this context?"
- **Options**: "Would you prefer [option A] or [option B]? What are the trade-offs?"
- **Edge Cases**: "What should happen if [error scenario]? How should the system recover?"
- **Examples**: "Can you provide an example of [data structure/workflow/error message]?"
- **Validation**: "Let me confirm my understanding: [summary]. Is this correct?"

### Context-Aware Expansion
- **If user mentions existing feature**: "You mentioned [feature]. Should we follow the same pattern? Any differences?"
- **If user mentions external service**: "What happens if [service] is down? Retry strategy? Timeout? Fallback?"
- **If user mentions complex calculation**: "Are there existing utilities for this? Performance requirements? Should results be cached?"
- **If user mentions sensitive data**: "What encryption/redaction is needed? Compliance requirements? Retention policy?"

### Standards Validation
- **After data model discussion**: "Let me validate against database standards: indexes, data isolation, soft delete, audit logging."
- **After API design discussion**: "Let me validate against API standards: OpenAPI docs, pagination, error responses, DTO validation."
- **After business logic discussion**: "Let me validate against error handling standards: result patterns, error codes, user-facing messages."

---

## Notes for AI Implementers

- **Be Adaptive**: Not every feature needs every question. Skip irrelevant sections.
- **Ask Incrementally**: Don't overwhelm with all questions at once. Ask 3-5 questions, wait for response, then continue.
- **Validate Against Standards**: Reference `standards.md` checklist to ensure completeness.
- **Provide Examples**: Use concrete examples from existing codebase when asking questions.
- **Summarize Periodically**: After each topic area, summarize understanding and confirm with user.
- **Flag Ambiguities**: If user response is unclear, ask for clarification immediately.
- **Suggest Defaults**: When user is unsure, suggest sensible defaults based on standards (e.g., "I recommend cursor-based pagination with default limit 20, max 100").
