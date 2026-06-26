# Backend Specification Standards

This document serves as a completeness checklist during backend specification generation. Each section contains specific requirements, best practices, and validation checkpoints that must be addressed in feature specifications.

---

## Table of Contents

| Section | Line | Description |
|---------|------|-------------|
| [API Design Standards](#api-design-standards) | 25 | REST conventions, OpenAPI, pagination, DTOs, error responses |
| [Database Standards](#database-standards) | 116 | Schema design, migrations, indexes, ORM patterns, audit trails |
| [Authentication & Authorization](#authentication--authorization-standards) | 201 | Auth provider, RBAC, security guards, multi-tenant security |
| [Error Handling Standards](#error-handling-standards) | 280 | Result pattern, error codes, localized messages, recovery |
| [Caching Standards](#caching-standards) | 367 | Cache strategies, TTL, key naming, invalidation, hit rates |
| [Security Standards](#security-standards) | 456 | OWASP Top 10, input validation, rate limiting, CORS, headers |
| [Performance Standards](#performance-standards) | 556 | Response times, N+1 prevention, query optimization, async processing |
| [Testing Standards](#testing-standards) | 643 | Coverage targets, AAA pattern, mocking, test organization |
| [Logging & Monitoring](#logging--monitoring-standards) | 779 | Structured logging, log levels, PII redaction, alerting |
| [Multi-Tenancy Standards](#multi-tenancy-standards) | 912 | Tenant isolation, composite indexes, cross-tenant prevention |
| [Clean Architecture Standards](#clean-architecture-standards) | 1032 | Layer dependency rule, layer responsibilities, utilities |
| [Specification Completeness Checklist](#specification-completeness-checklist) | 1136 | Final validation checklist for all backend specs |

---

## API Design Standards

### REST Conventions
- **Resource Naming**: Use plural nouns (`/users`, `/organizations`, `/tasks`)
- **HTTP Methods**: GET (read), POST (create), PATCH (partial update), PUT (replace), DELETE (remove)
- **Status Codes**: 200 (OK), 201 (Created), 204 (No Content), 400 (Bad Request), 401 (Unauthorized), 403 (Forbidden), 404 (Not Found), 409 (Conflict), 422 (Validation Error), 500 (Internal Error)
- **Idempotency**: POST operations should generate idempotency keys; PUT/PATCH/DELETE are naturally idempotent

### OpenAPI 3.1 Alignment
- All endpoints must have OpenAPI documentation with:
  - Operation summary and description
  - Request/response schemas
  - Security requirements (bearerAuth)
  - Example payloads
  - Error response schemas (RFC 7807)
<!-- Consult project CLAUDE.md for framework-specific OpenAPI decorators/annotations -->

### Versioning
- URL-based versioning: `/api/v1/resource`
- Version increments for breaking changes only
- Maintain backward compatibility within major version

### Pagination
- **Cursor-Based Pagination** (required for all list endpoints):
  ```typescript
  {
    cursor?: string;        // Opaque cursor token
    limit?: number;         // Default: 20, Max: 100
  }
  ```
- Response format:
  ```typescript
  {
    data: T[];
    pagination: {
      nextCursor: string | null;
      hasMore: boolean;
      total?: number;       // Optional, expensive to compute
    }
  }
  ```
<!-- Consult project CLAUDE.md or ORM docs for cursor/take implementation -->
- Never use offset-based pagination (performance issues at scale)

### Filtering & Sorting
- Query parameters for filters: `?status=ACTIVE&createdAfter=2025-01-01`
- Sorting: `?sortBy=createdAt&sortOrder=desc`
<!-- Consult project CLAUDE.md for the validation library used (e.g., class-validator, Zod, Joi) -->

### Error Responses (RFC 7807)
- Standard error structure:
  ```typescript
  {
    type: string;           // Error code (ERR_DOMAIN_XXX)
    title: string;          // English summary
    status: number;         // HTTP status
    detail: string;         // User-facing message (localized per project)
    instance?: string;      // Request path
    traceId?: string;       // Correlation ID for logging
  }
  ```
<!-- Consult project CLAUDE.md for the error handling pattern (e.g., Result/Either type, OperationResult) -->
<!-- Consult project CLAUDE.md for localized error message utilities -->

### DTO Validation
- Use the project's validation library on all DTOs
- Enable global validation pipe/middleware
- Create custom validators for domain-specific data (phone numbers, IDs, locale-specific text)
<!-- Consult project CLAUDE.md for validation library and existing custom validators -->

### Checkpoint Questions
- [ ] Are all endpoints documented with OpenAPI specs?
- [ ] Does pagination use cursor-based approach?
- [ ] Are error responses following RFC 7807 format?
- [ ] Are all DTOs validated with the project's validation library?
- [ ] Are localized error messages provided for user-facing errors?

---

## Database Standards

### Schema Design
- **Naming**: Follow the project's ORM naming conventions (check CLAUDE.md)
- **Primary Keys**: Use appropriate ID strategy (CUID, UUID, auto-increment per project)
- **Timestamps**: Every model must have `createdAt` and `updatedAt`
- **Soft Deletes**: Use `deletedAt` field instead of hard deletes
- **Multi-tenancy**: If the project uses multi-tenancy, every tenant-scoped model must include a tenant ID field with composite indexes

### Zero-Downtime Migrations
- **Additive Changes**: New columns must be nullable initially
- **Column Removal**: Three-step process:
  1. Deploy code that stops writing to column
  2. Deploy migration to drop column
  3. Remove column from ORM schema
- **Renaming**: Create new column, migrate data, drop old column
- **Data Migrations**: Use the ORM's migration tooling; edit SQL manually when needed
<!-- Consult project CLAUDE.md for ORM-specific migration commands -->

### Indexes
- **Single-Column Indexes**: For frequent WHERE/ORDER BY columns
- **Composite Indexes**: For multi-tenancy (tenantId + other field) and common query patterns
- **Unique Constraints**: For natural keys (email, slug within tenant)
- **Full-Text Search**: Use database-native full-text search with appropriate indexes for locale-specific search

### Constraints
- **Foreign Keys**: Use ORM relation decorators with `onDelete` and `onUpdate` actions
  - `Cascade`: Child records deleted when parent deleted
  - `SetNull`: Foreign key set to null (requires nullable field)
  - `Restrict`: Prevent deletion if children exist (default)
- **Check Constraints**: For business rules (e.g., amount > 0)
- **Not Null**: Avoid nullable fields unless semantically optional

### ORM Patterns
- **Selective Fetching**: Use select/include to avoid fetching unused columns
- **Transactions**: Use the ORM's transaction API for atomic operations
- **Batch Operations**: Use bulk create/update/delete for batch operations
- **Connection Pooling**: Configure appropriate pool size in database connection settings
<!-- Consult project CLAUDE.md for ORM-specific patterns and connection configuration -->

### Audit Trails
- **System Actions**: Log all Create, Update, Delete operations
- **Fields to Capture**:
  - `userId`: Who performed the action
  - `tenantId`: Tenant context (if multi-tenant)
  - `action`: Enum (CREATE, UPDATE, DELETE)
  - `entityType`: Model name
  - `entityId`: Record ID
  - `changes`: JSON field with before/after values
  - `timestamp`: When action occurred
  - `ipAddress`: Client IP (optional)

### Soft Deletes
- Add a nullable `deletedAt` timestamp field
- Filter queries to exclude soft-deleted records (`where: { deletedAt: null }`)
- Consider ORM middleware for automatic filtering
- Hard delete after retention period (e.g., 90 days)

### Checkpoint Questions
- [ ] Does the schema include createdAt, updatedAt, and deletedAt?
- [ ] Are composite indexes defined for tenant ID + frequently queried fields (if multi-tenant)?
- [ ] Is the migration strategy safe for zero-downtime deployment?
- [ ] Are foreign key constraints and cascade rules properly configured?
- [ ] Is audit logging planned for sensitive operations?

---

## Authentication & Authorization Standards

### Session Management
- Use the project's auth provider for session verification
- Protect endpoints with a session verification guard/decorator
- Session payload contains: userId, tenantId (if multi-tenant), role
- Implement token refresh via the auth provider's frontend SDK
- Implement session revocation on password change, role change, or security events
<!-- Consult project CLAUDE.md for auth provider and session guard decorators -->

### RBAC Permission Matrix

Define user roles appropriate to the project. Common pattern:

| Role | Description |
|------|-------------|
| Member | Basic access, read/write own resources |
| Power User | Member + advanced features, bulk operations |
| Admin | Power User + manage users, configure settings |
| Owner | Admin + billing, delete tenant, transfer ownership |
| System Admin | All permissions across all tenants, system configuration |

#### Resource Access Matrix
Document a role × resource × action matrix for each feature:

| Resource | Member | Admin | Owner | System Admin |
|----------|--------|-------|-------|--------------|
| Own resources | CRUD | CRUD | CRUD | CRUD |
| Others' resources | R | CRUD | CRUD | CRUD |
| Tenant settings | R | RU | CRUD | CRUD |
| User management | - | CRUD | CRUD | CRUD |
| Billing | - | R | CRUD | CRUD |
| System config | - | - | - | CRUD |

<!-- Consult project CLAUDE.md for actual role names and permission decorators -->

### Security Guards/Decorators

#### Session Verification
- Validates auth token/session
- Injects session object into request
- Apply to all protected endpoints

#### Access Control
- Validates user belongs to tenant/organization
- Checks minimum role requirement
- Prevents cross-tenant access

#### Resource Guards
- Checks resource-level prerequisites (e.g., credit balance, subscription tier)
- Prevents operations when prerequisites not met

### Multi-Tenant Security
- **Automatic Scoping**: All queries must filter by tenant ID
- **Guard Implementation**: Extract tenant ID from session, validate against request params
- **Cross-Tenant Prevention**: Never allow tenant ID override from client
- **System Admin Exception**: Can bypass tenant scoping for monitoring/support

### Checkpoint Questions
- [ ] Are all protected endpoints decorated with session verification?
- [ ] Is role-based access control enforced with appropriate guards?
- [ ] Are tenant boundaries validated for all tenant-scoped operations?
- [ ] Are resource prerequisites checked before expensive operations?
- [ ] Are system admin actions logged for audit purposes?

---

## Error Handling Standards

### Result Pattern
- **Never throw exceptions** from service layer
- Return a discriminated union (Result/Either) type:
  ```typescript
  type Result<T> =
    | { success: true; data: T }
    | { success: false; error: { code: string; message: string } };
  ```
- Usage:
  ```typescript
  // Success case
  return Result.success({ id: '123', name: 'Test' });

  // Error case
  return Result.error('ERR_USER_NOT_FOUND', 'User not found');
  ```
<!-- Consult project CLAUDE.md for the specific Result/OperationResult implementation -->

### Hierarchical Error Codes
- **Format**: `ERR_{DOMAIN}_{SPECIFIC_ERROR}`
- **Examples**:
  - `ERR_AUTH_INVALID_CREDENTIALS`
  - `ERR_DOCUMENT_INVALID_FORMAT`
  - `ERR_TENANT_INSUFFICIENT_CREDITS`
  - `ERR_USER_ALREADY_EXISTS`
  - `ERR_PERMISSION_DENIED`
  - `ERR_VALIDATION_FAILED`
  - `ERR_RESOURCE_NOT_FOUND`
  - `ERR_RATE_LIMIT_EXCEEDED`
- **Centralized Definition**: Define error codes in domain-specific enums
- **HTTP Mapping**: Map error codes to HTTP status codes in controller exception filter

### Localized User-Facing Messages
- Implement a localized error message utility that maps error codes to user-facing messages
- Provide fallback for unknown codes
- Support interpolation for dynamic messages
- User-facing messages in the project's target locale, technical messages in English for logs
<!-- Consult project CLAUDE.md for localization requirements and error message utilities -->

### Recovery Strategies

#### Idempotency
- **POST Operations**: Accept `Idempotency-Key` header
- **Storage**: Store key + response in cache (TTL: 24 hours)
- **Behavior**: Return cached response if duplicate key detected
- **Implementation**: Idempotency middleware

#### Circuit Breaker
- **Pattern**: Fail fast when downstream service unavailable
- **States**: Closed (normal) → Open (failing) → Half-Open (testing recovery)
- **Configuration**: Failure threshold, timeout, recovery interval
- **Use Cases**: External API calls, email service, payment gateway

#### Retry Logic
- **Transient Errors**: Network timeouts, 503 responses, deadlocks
- **Exponential Backoff**: 100ms, 200ms, 400ms, 800ms intervals
- **Max Attempts**: 3-5 retries depending on operation criticality
- **Non-Retryable**: 4xx errors (except 429), validation failures

#### Graceful Degradation
- **Feature Flags**: Disable non-critical features during incidents
- **Fallback Responses**: Return cached/stale data with warning
- **Queue Deferral**: Defer non-urgent operations to background queue

### Logging Error Context
- **Structured Logging**: Include error code, user ID, tenant ID, trace ID
- **Stack Traces**: Log full stack for 5xx errors, omit for 4xx
- **PII Redaction**: Never log sensitive data (passwords, tokens, credit cards)
- **Error Aggregation**: Use correlation IDs to trace error chains

### Checkpoint Questions
- [ ] Do all service methods return a Result type instead of throwing?
- [ ] Are error codes hierarchical and well-documented?
- [ ] Are localized error messages provided for all user-facing errors?
- [ ] Are retry and circuit breaker strategies defined for external dependencies?
- [ ] Is error logging structured with appropriate context?

---

## Caching Standards

### Cache Strategies

#### Cache-Aside Pattern
- **Read Flow**:
  1. Check cache
  2. If miss, query database
  3. Store result in cache
  4. Return result
- **Write Flow**:
  1. Update database
  2. Invalidate cache
  3. Next read will repopulate cache
- **Use Cases**: Frequently read, infrequently updated data

#### Write-Through Pattern
- **Write Flow**:
  1. Update cache
  2. Update database
  3. Return result
- **Use Cases**: Session data, counters, real-time analytics

#### Cache Warming
- **Strategy**: Pre-populate cache on application startup or scheduled jobs
- **Use Cases**: Common queries, tenant settings, user preferences

### TTL Configuration
- **Short TTL (1-5 minutes)**: Real-time data (credit balance, active sessions)
- **Medium TTL (15-60 minutes)**: Semi-static data (tenant settings, user profiles)
- **Long TTL (1-24 hours)**: Static data (lookup tables, system configuration)
- **No TTL**: Manual invalidation only (rare, high consistency requirements)

### Key Naming Convention
- **Format**: `{domain}:{resource}:{identifier}:{subresource?}`
- **Examples**:
  - `tenant:123:settings`
  - `user:456:profile`
  - `task:789:status`
  - `tenant:123:credits:balance`
- **Benefits**: Namespace isolation, pattern-based invalidation, debugging clarity

### Invalidation Strategies

#### Explicit Invalidation
- Delete cache key after update

#### Pattern-Based Invalidation
- Delete multiple keys matching pattern
- Warning: key-scan operations can be expensive; use cursor-based iteration for large datasets

#### Event-Driven Invalidation
- Emit domain events, listeners invalidate related caches
- Example: `UserUpdated` event invalidates user profile and tenant member list

#### Time-Based Invalidation
- Rely on TTL expiration for eventually consistent data
- Combine with manual invalidation for critical updates

### Hit Rate Targets
- **Minimum**: 80% cache hit rate for frequently accessed data
- **Ideal**: 95%+ for hot paths (dashboard data, user sessions)
- **Monitoring**: Track hit/miss metrics, alert on degradation
- **Optimization**: Increase TTL, improve key design, add cache warming

### Cache Stampede Prevention
- **Problem**: Multiple requests fetch same data simultaneously on cache miss
- **Solution**: Use distributed lock or cache null results temporarily

### Checkpoint Questions
- [ ] Is caching strategy (cache-aside, write-through) appropriate for data access pattern?
- [ ] Are TTL values configured based on data volatility?
- [ ] Do cache keys follow naming convention for clarity and invalidation?
- [ ] Is cache invalidation synchronized with database updates?
- [ ] Are hit rate targets defined and monitored?

---

## Security Standards

### OWASP Top 10 Mitigation

#### A01: Broken Access Control
- Enforce RBAC at every endpoint
- Validate tenant ID in all tenant-scoped queries
- Never trust client-provided IDs without authorization check
<!-- Consult project CLAUDE.md for access control decorators/guards -->

#### A02: Cryptographic Failures
- Use bcrypt for password hashing (cost factor: 12)
- Store sensitive data encrypted at rest (AES-256)
- Use HTTPS/TLS for all communication
- Never log sensitive data (passwords, tokens, PII)

#### A03: Injection
- Use parameterized queries via the ORM (prevents SQL injection)
- Validate and sanitize all user inputs with the project's validation library
- Sanitize HTML content when accepting rich text
<!-- Consult project CLAUDE.md for locale-specific text sanitization requirements -->

#### A04: Insecure Design
- Follow clean architecture with explicit security boundaries
- Implement defense-in-depth: validate at frontend, controller, service, domain
- Use threat modeling for sensitive features (payment, file upload)

#### A05: Security Misconfiguration
- No default passwords or credentials
- Disable debug mode in production
- Configure CORS restrictively (whitelist origins)
- Security headers: CSP, X-Frame-Options, X-Content-Type-Options

#### A06: Vulnerable Components
- Run dependency audit regularly
- Auto-update dependencies with Dependabot/Renovate
- Monitor CVE databases for critical libraries

#### A07: Authentication Failures
- Use the project's auth provider for session management
- Implement rate limiting on login endpoints
- Enforce strong password policy (min 8 chars, complexity)
- Multi-factor authentication for admin roles

#### A08: Software and Data Integrity Failures
- Sign and verify file uploads
- Use content hashing for uploaded files
- Verify package integrity (lock files)

#### A09: Logging Failures
- Log all authentication attempts (success and failure)
- Log authorization failures with user context
- Centralized logging with structured JSON
- PII redaction in logs

#### A10: Server-Side Request Forgery
- Validate and whitelist URLs for external requests
- Use separate service account for external API calls
- Network segmentation (DMZ for external-facing services)

### Input Validation
- **DTO Validation**: Use the project's validation library on all DTOs
- **Custom Validators**: Domain-specific validators (phone numbers, ID numbers, locale-specific text)
- **Sanitization**: Strip dangerous characters, normalize Unicode
- **Length Limits**: Enforce max length on all string fields
- **Type Coercion**: Use safe type conversion utilities
<!-- Consult project CLAUDE.md for existing validation utilities and custom validators -->

### Rate Limiting
- **Strategy**: Token bucket or sliding window
- **Limits**:
  - Authentication: 5 requests/minute per IP
  - API (authenticated): 100 requests/minute per user
  - API (public): 20 requests/minute per IP
  - File uploads: 10 requests/hour per user
- **Response**: 429 Too Many Requests with `Retry-After` header
<!-- Consult project CLAUDE.md for rate limiting library/middleware -->

### CORS Configuration
- **Production**: Whitelist specific origins
- **Development**: Allow localhost dev server origins
- **Credentials**: Enable `credentials: true` for cookies/sessions
- **Methods**: Restrict to necessary methods (GET, POST, PATCH, DELETE)
- **Headers**: Whitelist required headers (Authorization, Content-Type)

### Security Headers
- Enable all default protections (e.g., Helmet.js or equivalent)
- **CSP**: Define Content Security Policy for XSS prevention
- **X-Frame-Options**: `DENY` to prevent clickjacking
- **X-Content-Type-Options**: `nosniff` to prevent MIME sniffing
- **Strict-Transport-Security**: Force HTTPS with max-age=31536000

### No console.log
- **Backend**: Use structured logging infrastructure
  - Never use `console.log`, `console.error`, etc.
  - Use the project's injected logger service
- **Rationale**: console.log exposes data in production, lacks structure, difficult to filter
- **Linting**: Enforce `no-console` lint rule
<!-- Consult project CLAUDE.md for logging infrastructure -->

### Checkpoint Questions
- [ ] Are all OWASP Top 10 vulnerabilities addressed?
- [ ] Is input validation comprehensive (DTOs, custom validators)?
- [ ] Are rate limits configured for all sensitive endpoints?
- [ ] Is CORS restricted to trusted origins?
- [ ] Are security headers configured?
- [ ] Is console.log usage eliminated in favor of proper logging?

---

## Performance Standards

### Response Time Targets

#### CRUD Operations
- **p50 (median)**: < 100ms
- **p95**: < 500ms
- **p99**: < 1s
- **Scope**: Simple database queries (single table, indexed fields)

#### Processing Operations
- **p50**: < 500ms
- **p95**: < 2s
- **p99**: < 5s
- **Scope**: Complex calculations, file processing, multi-step workflows
- **Async Pattern**: Operations > 5s should use background jobs

#### Background Jobs
- **Latency**: Queue time < 1s, processing time varies by job
- **Throughput**: Scale workers to maintain queue depth < 100
- **Monitoring**: Track job success rate, retry count, dead letter queue

### N+1 Query Prevention
- **Problem**: Loop that triggers query per iteration
- **Solution**: Use ORM eager loading (include/join) to fetch relations in a single query
- **Detection**: Enable query logging in development, analyze query counts
- **Testing**: Assert query count in integration tests

### Database Query Optimization
- **Indexes**: Add indexes for all WHERE, ORDER BY, JOIN columns
- **Composite Indexes**: Match query patterns (e.g., `[tenantId, createdAt]`)
- **Select Only Needed Fields**: Use select to avoid fetching unused columns
- **Batch Operations**: Use bulk queries instead of loops
- **Pagination**: Cursor-based pagination for large datasets
- **Explain Plans**: Run `EXPLAIN ANALYZE` for slow queries, optimize based on output

### Connection Pooling
- **Configuration**: Set connection pool size in database connection URL or config
  - Development: 5-10 connections
  - Production: 20-50 connections (tune based on load)
- **Health Checks**: Monitor active/idle connections, alert on pool exhaustion
- **Timeout**: Configure connect and pool timeouts to fail fast

### Caching Strategy
- **Hot Paths**: Cache frequently accessed data (tenant settings, user profiles)
- **Cache Hit Rate**: Target 80%+ for cached endpoints
- **TTL**: Balance freshness vs. performance (see Caching Standards section)
- **Warming**: Pre-populate cache on startup for predictable queries

### Async Processing
- **When to Use**: Operations taking > 5 seconds, non-critical paths, batch jobs
- **Implementation**: Use a message queue with a persistent backend (e.g., Redis, RabbitMQ)
- **Queues**: Separate queues by priority (high, default, low)
- **Worker Scaling**: Horizontal scaling based on queue depth
- **Failure Handling**: Exponential backoff retry, dead letter queue after 3 attempts
<!-- Consult project CLAUDE.md for queue library (e.g., BullMQ, Celery, Sidekiq) -->

### Response Compression
- **Gzip**: Enable compression middleware for responses > 1KB
- **Brotli**: Use for static assets (better compression, slower)
- **Exclusions**: Don't compress images, videos, already-compressed formats

### Monitoring & Profiling
- **APM**: Use Application Performance Monitoring (e.g., New Relic, DataDog)
- **Metrics**: Track response times, error rates, throughput per endpoint
- **Alerts**: P95 response time > 500ms, error rate > 1%, queue depth > 100
- **Profiling**: Profile slow endpoints with flamegraphs, optimize bottlenecks

### Checkpoint Questions
- [ ] Are response time targets defined for each endpoint category?
- [ ] Is N+1 query prevention validated in tests?
- [ ] Are database indexes aligned with query patterns?
- [ ] Is connection pooling configured for production load?
- [ ] Are operations > 5s moved to background jobs?
- [ ] Is response compression enabled for API responses?

---

## Testing Standards

### Coverage Targets
- **Overall**: 80% line coverage
- **Business Logic**: 95% coverage (domain services, orchestration)
- **Critical Paths**: 100% coverage (auth, payment, core data processing)
- **Exclusions**: Boilerplate (DTOs, entities), third-party integrations (mock instead)

### AAA Pattern (Arrange-Act-Assert)
```typescript
describe('UserService', () => {
  it('should create user with valid data', async () => {
    // Arrange
    const createUserDto = { email: 'test@example.com', name: 'Test User' };
    const mockUser = { id: '123', ...createUserDto };
    mockRepository.create.mockResolvedValue(mockUser);

    // Act
    const result = await userService.create(createUserDto);

    // Assert
    expect(result.success).toBe(true);
    expect(result.data).toEqual(mockUser);
    expect(mockRepository.create).toHaveBeenCalledWith({
      data: createUserDto
    });
  });
});
```

### Mocking
- Use type-safe mocking libraries for interfaces and complex objects
- Benefits: Autocomplete, compile-time errors for incorrect mocks, reduces test brittleness
<!-- Consult project CLAUDE.md for the specific mocking library (e.g., jest-mock-extended, vitest, sinon) -->

### No Skipping Tests
- **Rule**: Never use `.skip()` or `xit()` because mocking is complex
- **Rationale**: Skipped tests give false sense of coverage, degrade over time
- **Solution**: Use proper mocking libraries for complex interfaces, isolate dependencies
- **Exception**: Temporarily skip flaky tests, but add TODO comment with issue tracker link

### Test Organization
- **Unit Tests**: Test single class/function in isolation, mock all dependencies
  - Location: Next to source file (e.g., `*.spec.ts` or `*.test.ts`)
  - Naming: `ClassName.spec.ts`
- **Integration Tests**: Test multiple components together, use real database
  - Location: Dedicated test directory (e.g., `test/integration/`)
  - Naming: `feature-name.integration.spec.ts`
  - Setup: Use test database, seed data, teardown after each test
- **E2E Tests**: Test full user flows via HTTP
  - Location: Dedicated test directory (e.g., `test/e2e/`)
  - Naming: `feature-name.e2e.spec.ts`
  - Setup: Use test database, auth provider test mode, cleanup after suite

### Test Data Management
- **Factories**: Use factory pattern for test data generation
  ```typescript
  export const createMockUser = (overrides?: Partial<User>): User => ({
    id: 'test-user-123',
    email: 'test@example.com',
    name: 'Test User',
    role: 'member',
    ...overrides
  });
  ```
- **Builders**: Fluent API for complex object construction
- **Fixtures**: Static test data for integration tests (JSON files)
- **Cleanup**: Use `afterEach()` to reset mocks and database state

### Testing Async Operations
- **Always await**: Prevent floating promises in tests
- **Test both success and failure**: Cover happy path and error scenarios
- **Timeout Configuration**: Set reasonable timeouts for slow operations

### Testing Error Handling
- **Result Pattern**: Test both success and error branches
  ```typescript
  it('should return error when user not found', async () => {
    mockRepository.findById.mockResolvedValue(null);

    const result = await userService.findById('invalid-id');

    expect(result.success).toBe(false);
    expect(result.error.code).toBe('ERR_USER_NOT_FOUND');
  });
  ```
- **Error Codes**: Verify correct error codes returned
- **Localized Messages**: Test localized error message retrieval

### Testing Multi-Tenancy
- **Tenant Isolation**: Test that users cannot access other tenants' data
  ```typescript
  it('should not allow cross-tenant access', async () => {
    const user = createMockUser({ tenantId: 'tenant-123' });
    const document = createMockDocument({ tenantId: 'tenant-456' });

    const result = await documentService.findById(document.id, user);

    expect(result.success).toBe(false);
    expect(result.error.code).toBe('ERR_PERMISSION_DENIED');
  });
  ```
- **System Admin Exception**: Test that system admins can access all tenants

### Snapshot Testing
- **Use Sparingly**: Only for complex output structures (DTOs, API responses)
- **Review Changes**: Always review snapshot diffs before updating
- **Avoid for Business Logic**: Use explicit assertions instead

### Performance Testing
- **Load Tests**: Test API under realistic load (e.g., 100 concurrent users)
- **Stress Tests**: Test system limits (e.g., 1000 concurrent requests)
- **Tools**: Artillery, k6, or custom scripts
- **Metrics**: Response time percentiles, error rate, throughput

### Checkpoint Questions
- [ ] Are coverage targets met (80% overall, 95% business logic, 100% critical)?
- [ ] Do tests follow AAA pattern consistently?
- [ ] Is the mocking library used properly for complex mocking?
- [ ] Are there zero skipped tests (or documented exceptions)?
- [ ] Are both success and error paths tested?
- [ ] Is multi-tenancy isolation validated in tests?

---

## Logging & Monitoring Standards

### Structured JSON Logging
- **Format**: Newline-delimited JSON (NDJSON)
  ```json
  {
    "timestamp": "2025-01-27T10:30:45.123Z",
    "level": "info",
    "message": "User created successfully",
    "userId": "user-123",
    "tenantId": "tenant-456",
    "traceId": "trace-789",
    "context": {
      "email": "test@example.com",
      "role": "member"
    }
  }
  ```
- **Benefits**: Machine-parseable, queryable, structured context
<!-- Consult project CLAUDE.md for the logging library (e.g., Winston, Pino, Bunyan) -->

### Log Levels
- **ERROR**: Errors requiring immediate attention (5xx responses, unhandled exceptions)
- **WARN**: Recoverable issues (deprecated API usage, fallback triggered, rate limit approaching)
- **INFO**: Important business events (user created, processing completed, payment processed)
- **DEBUG**: Detailed diagnostic information (query execution, cache hit/miss, external API calls)
- **TRACE**: Very verbose logging (rarely used, performance impact)

### Log Level Configuration
- **Production**: INFO (or WARN to reduce noise)
- **Staging**: DEBUG
- **Development**: DEBUG or TRACE
- **Environment Variable**: `LOG_LEVEL=info`

### PII Redaction
- **Sensitive Fields**: password, token, creditCard, ssn, apiKey, sessionId
- **Redaction Strategy**: Replace with `[REDACTED]` or hash (SHA-256)
- **Middleware**: Implement automatic PII redaction in logger configuration

### Contextual Logging
- **Request Context**: Include traceId, userId, tenantId in all logs
- **Implementation**: Use async context propagation (e.g., `AsyncLocalStorage`) or request-scoped logger

### Correlation IDs (Trace IDs)
- **Purpose**: Track single request across services and async jobs
- **Generation**: UUID v4 generated at entry point (API gateway or controller)
- **Propagation**: Pass via header (`X-Trace-Id`) or message metadata
- **Logging**: Include in all log entries for request lifetime

### Performance Logging
- **Query Logging**: Log slow queries (> 100ms)
- **Request Duration**: Log request processing time with method, path, status, and duration

### Error Logging
- **Stack Traces**: Log full stack trace for 5xx errors
- **Error Context**: Include user action, input data (redacted), system state
- **Aggregation**: Use correlation IDs to group related errors

### Monitoring & Alerting
- **Metrics to Track**:
  - Error rate (per endpoint, per tenant)
  - Response time percentiles (p50, p95, p99)
  - Throughput (requests per second)
  - Database query count and duration
  - Cache hit rate
  - Queue depth and processing time
  - Active sessions
- **Alerting Thresholds**:
  - Error rate > 1% (5 minutes)
  - P95 response time > 500ms (5 minutes)
  - Queue depth > 100 (10 minutes)
  - Cache hit rate < 80% (15 minutes)
  - Database connection pool > 90% (immediate)
- **Tools**: Prometheus + Grafana, DataDog, New Relic, CloudWatch

### Log Retention
- **Hot Storage**: 7 days (fast query, high cost)
- **Warm Storage**: 30 days (slower query, medium cost)
- **Cold Storage**: 1 year (archive, low cost)
- **Legal Hold**: Retain audit logs for 7 years (compliance)

### Checkpoint Questions
- [ ] Is logging structured (JSON format)?
- [ ] Are log levels used appropriately (ERROR, WARN, INFO, DEBUG)?
- [ ] Is PII automatically redacted from logs?
- [ ] Are correlation IDs (trace IDs) included in all log entries?
- [ ] Are slow queries and long requests logged?
- [ ] Are monitoring metrics and alerting thresholds defined?

---

## Multi-Tenancy Standards

> **Applicability**: This section applies only to projects that use multi-tenancy or data isolation. Check project CLAUDE.md for multi-tenancy requirements.

### Tenant Isolation
- **Data Scoping**: Every tenant-scoped model must include a tenant ID field
- **Query Filtering**: All queries must filter by tenant ID
- **Authorization**: Validate tenant ID in request matches session
- **Defense-in-Depth**: Enforce at controller, service, and database layers

### Composite Indexes
- **Pattern**: Every query filter should have matching composite index
- **Index tenant ID + frequently queried fields** (e.g., `[tenantId, createdAt]`, `[tenantId, status]`)
- **Query Optimization**: Indexes should match ORDER BY and WHERE clauses

### Data Scoping Helpers
- **Base Repository Pattern**: Abstract common scoping logic
  ```typescript
  export abstract class TenantScopedRepository<T> {
    protected scopeToTenant(tenantId: string) {
      return { tenantId, deletedAt: null };
    }

    async findMany(tenantId: string, where?: object) {
      return this.orm.model.findMany({
        where: { ...this.scopeToTenant(tenantId), ...where }
      });
    }
  }
  ```

### Cross-Tenant Access Prevention
- **Explicit Check**: Never allow client to override tenant ID
- **Extract from session**: Always use tenant ID from the authenticated session, not from URL params or headers
- **Validate**: If tenant ID appears in URL params, validate it matches the session's tenant ID

### System Admin Exception Handling
- **Use Cases**: Support dashboards, system monitoring, data exports
- **Implementation**: Conditionally omit tenant ID filter for system admin role
- **Audit Logging**: Log all system admin cross-tenant accesses

### Shared vs Tenant-Scoped Resources
- **Shared Resources** (no tenant ID):
  - System configuration
  - Lookup tables (countries, currencies)
  - Platform-wide analytics
- **Tenant-Scoped Resources** (requires tenant ID):
  - Users (belongs to tenant)
  - Business entities
  - Billing, subscriptions
  - Tenant settings

### Testing Multi-Tenancy
- **Isolation Tests**: Verify users cannot access other tenants' data
- **System Admin Tests**: Verify admins can access all tenants
- **Index Tests**: Verify composite indexes exist for all scoped queries

### Checkpoint Questions
- [ ] Does every tenant-scoped model include a tenant ID field?
- [ ] Are composite indexes defined for tenant ID + frequently queried fields?
- [ ] Is tenant ID validated in all tenant-scoped queries?
- [ ] Are cross-tenant access attempts prevented and logged?
- [ ] Is system admin exception handling implemented securely?
- [ ] Are multi-tenancy isolation tests passing?

---

## Clean Architecture Standards

### Layer Dependency Rule
- **Rule**: Dependencies flow ONE direction only—higher layers import lower layers, never reverse
- **Layer Hierarchy** (lowest to highest):
  0. **Infrastructure**: Database, cache, file storage, logging
  1. **Application Infrastructure**: Auth, sessions, guards (often global/cross-cutting)
  2. **Domain**: Business logic modules (one per domain entity)
  3. **Orchestration**: Workflow coordinators, multi-domain operations
  4. **API**: Controllers (entry points)

<!-- Consult project CLAUDE.md for the specific layer structure and naming conventions -->

### Layer Responsibilities

#### Layer 0: Infrastructure
- **Purpose**: Low-level technical concerns, no business logic
- **Components**: Database ORM, cache client, file storage, logging infrastructure, external service clients
- **Dependencies**: None (or only external libraries)

#### Layer 1: Application Infrastructure
- **Purpose**: Cross-cutting concerns available everywhere
- **Components**: Authentication integration, session management, security guards, global filters, request context
- **Dependencies**: Layer 0 only

#### Layer 2: Domain
- **Purpose**: Business logic modules, one per domain entity
- **Structure**: Each domain has services, repositories, DTOs
- **Dependencies**: Layer 0, Layer 1, shared types/interfaces

#### Layer 3: Orchestration
- **Purpose**: Coordinate multiple domain services, implement workflows
- **Use Cases**: Multi-step processes, cross-domain operations, saga patterns
- **Dependencies**: Layer 0, Layer 1, Layer 2, shared types/interfaces

#### Layer 4: API (Controllers)
- **Purpose**: HTTP entry points, request/response handling
- **Responsibilities**: Route definition, DTO validation, security decorators, call orchestration or domain services, map service results to HTTP responses
- **Dependencies**: All lower layers

### Shared Types / Domain Core
- **Purpose**: Interfaces and types shared across domains
- **Contents**: Domain interfaces, shared enums, common types (pagination, filters)
- **Dependencies**: None
- **Usage**: Allows orchestration layer to depend on abstractions, not concrete implementations

### Shared Utilities
- **Purpose**: Pure functions, utilities available everywhere
- **Categories**: Result types, text utilities, file utilities, constants, generic TypeScript types
- **Dependencies**: None (or only external libraries)
- **Rule**: No business logic, only reusable technical utilities
<!-- Consult project CLAUDE.md for existing shared utilities before creating new ones -->

### Dependency Injection
- **Pattern**: Constructor injection for all dependencies
- **Benefits**: Testability, loose coupling, explicit dependencies
- **Circular Dependencies**: Forbidden, refactor to shared interface or orchestration layer

### Module Organization
- **Feature Modules**: One module per domain
- **Global Module**: Application infrastructure (auth, guards)
- **Root Module**: Imports all feature modules
<!-- Consult project CLAUDE.md for framework-specific module patterns -->

### Checkpoint Questions
- [ ] Are dependencies flowing in one direction (higher → lower layers)?
- [ ] Is the application infrastructure module registered as global/cross-cutting?
- [ ] Are domain services focused on single business entity?
- [ ] Are orchestration services coordinating multiple domains?
- [ ] Are reusable utilities checked before creating new ones?
- [ ] Are shared types used for cross-domain interfaces?

---

## Specification Completeness Checklist

Use this final checklist to validate that a backend specification covers all required standards:

### API Design
- [ ] REST conventions followed (resource naming, HTTP methods, status codes)
- [ ] OpenAPI documentation complete
- [ ] Pagination strategy defined (cursor-based)
- [ ] Filtering and sorting parameters documented
- [ ] Error responses follow RFC 7807 format
- [ ] DTOs validated with project's validation library

### Database
- [ ] ORM schema updated with new models/fields
- [ ] Migration strategy is zero-downtime safe
- [ ] Indexes defined for query patterns (including composite for multi-tenancy)
- [ ] Foreign key constraints and cascade rules configured
- [ ] Audit trail implemented for sensitive operations
- [ ] Soft delete strategy (deletedAt) implemented

### Authentication & Authorization
- [ ] Session verification applied to protected endpoints
- [ ] RBAC enforced with appropriate guards/decorators
- [ ] Permission matrix documented for feature
- [ ] Resource prerequisites validated (if applicable)
- [ ] Multi-tenant isolation enforced (if applicable)

### Error Handling
- [ ] Services return Result type (never throw exceptions)
- [ ] Error codes hierarchical and documented (ERR_DOMAIN_XXX)
- [ ] Localized user-facing messages provided
- [ ] Recovery strategies defined (idempotency, retry, circuit breaker)
- [ ] Error logging includes structured context

### Caching
- [ ] Caching strategy chosen (cache-aside, write-through)
- [ ] TTL values configured based on data volatility
- [ ] Cache keys follow naming convention ({domain}:{resource}:{id})
- [ ] Invalidation strategy synchronized with database updates
- [ ] Hit rate targets defined

### Security
- [ ] OWASP Top 10 vulnerabilities addressed
- [ ] Input validation comprehensive (DTOs, custom validators)
- [ ] Rate limiting configured for endpoints
- [ ] CORS restricted to trusted origins
- [ ] Security headers configured
- [ ] No console.log usage (proper logging infrastructure)

### Performance
- [ ] Response time targets defined (p50, p95, p99)
- [ ] N+1 query prevention validated
- [ ] Database indexes aligned with query patterns
- [ ] Connection pooling configured
- [ ] Operations > 5s moved to background jobs
- [ ] Response compression enabled

### Testing
- [ ] Coverage targets defined (80% overall, 95% business logic, 100% critical)
- [ ] Tests follow AAA pattern
- [ ] Mocking library used for complex mocking
- [ ] No skipped tests (or documented exceptions)
- [ ] Both success and error paths tested
- [ ] Multi-tenancy isolation validated in tests (if applicable)

### Logging & Monitoring
- [ ] Logging structured (JSON format)
- [ ] Log levels used appropriately
- [ ] PII automatically redacted
- [ ] Correlation IDs (trace IDs) included
- [ ] Slow queries and long requests logged
- [ ] Monitoring metrics and alerting thresholds defined

### Multi-Tenancy (if applicable)
- [ ] Tenant ID included in all tenant-scoped models
- [ ] Composite indexes for tenant ID + query fields
- [ ] Tenant ID validated in all scoped queries
- [ ] Cross-tenant access prevented and logged
- [ ] System admin exception handling secure
- [ ] Multi-tenancy isolation tests passing

### Clean Architecture
- [ ] Dependencies flow one direction (higher → lower layers)
- [ ] Correct layer chosen for new code
- [ ] Reusable utilities checked before creating new ones
- [ ] Shared types used for cross-domain interfaces
- [ ] No circular dependencies
- [ ] Module structure follows feature organization
