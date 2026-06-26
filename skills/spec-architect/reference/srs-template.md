---
version: "1.0.0"
status: draft
project: "[project-name]"
feature: "[feature-name]"
active-layers: [backend, frontend]  # layers this feature touches; any of: backend, frontend, infrastructure
related-specs: []
created: "[YYYY-MM-DD]"
updated: "[YYYY-MM-DD]"
---

# Software Requirements Specification: [Feature Name]

<!--
This template follows IEEE 830 standard and is optimized for AI implementation.
Replace all [placeholders] with actual values. Remove sections not relevant to this feature's active layers.
Consult the project's CLAUDE.md for project-specific conventions, patterns, and constraints.
-->

## 1. Objective

### 1.1 Goal

<!-- One clear sentence describing what this feature accomplishes -->

[Describe the primary goal of this feature in one sentence]

### 1.2 Success Criteria

<!-- Measurable outcomes that define completion -->

- [ ] [Specific, measurable criterion 1]
- [ ] [Specific, measurable criterion 2]
- [ ] [Specific, measurable criterion 3]

---

## 2. Context & Constraints

### 2.1 Business Context

<!-- Why this feature is needed, what problem it solves -->

**Problem Statement:**
[Describe the business problem or user need this addresses]

**Business Value:**
[Explain the value this feature provides to users or the organization]

**User Impact:**
[Describe which users are affected and how]

### 2.2 Technical Context

**Architecture Layer:**
<!-- Specify which layer/module this belongs to per the project's architecture — consult CLAUDE.md -->
- Layer/Module: [per project architecture — consult CLAUDE.md]

**Related Modules:**
<!-- List modules this feature interacts with -->
- [Module 1] - [Relationship description]
- [Module 2] - [Relationship description]

**Existing Utilities:**
<!-- Critical: Always check project CLAUDE.md for reusable utilities before creating new code -->
- `[utility-file]` - [Functionality provided]
- `[utility-file]` - [Functionality provided]

**Dependencies:**
<!-- External packages or services required -->
- [Package/Service 1] - [Purpose]
- [Package/Service 2] - [Purpose]

### 2.3 Constraints

#### Localization
<!-- Conditional: Include this section if the project requires localization (RTL, i18n, specific character sets). Consult CLAUDE.md for specifics. -->
- [ ] Text normalization per project localization requirements
- [ ] RTL layout support with CSS logical properties (if applicable)
- [ ] Character set validation where applicable

#### Data Isolation
<!-- Conditional: Include this section if the project uses multi-tenancy or data isolation. Consult CLAUDE.md for specifics. -->
- [ ] All queries scoped by [isolation key — e.g., tenantId, orgId]
- [ ] Access control enforcement using [auth/access-control guards per CLAUDE.md]
- [ ] Session validation using [session guard per CLAUDE.md]

#### Performance
- Response time: [p50: Xms, p95: Yms, p99: Zms]
- Database queries: [Max N queries per request]
- File operations: [Max size, timeout constraints]

#### Security
- [ ] Input validation at all layers (Frontend → Controller → Business → Domain)
- [ ] No sensitive data in logs
- [ ] Rate limiting: [X requests per Y seconds]

### 2.4 Scope Boundaries

**In Scope:**
- [Feature/capability 1]
- [Feature/capability 2]
- [Feature/capability 3]

**Out of Scope:**
- [Excluded feature/capability 1]
- [Excluded feature/capability 2]
- [Excluded feature/capability 3]

---

## 3. Tech Stack

<!-- Only include sections relevant to the feature's active layers. Consult CLAUDE.md for project-specific tech stack. -->

### 3.1 Backend
<!-- If backend is an active layer -->

**Framework:**
- [Framework] [version]
- [ORM/Data layer] [version]

**Key Packages:**
- [package-name] - [Purpose]
- [package-name] - [Purpose]

**Patterns:**
- [Error handling pattern per CLAUDE.md]
- [DI/module system per CLAUDE.md]
- [Additional patterns specific to this feature]

### 3.2 Frontend
<!-- If frontend is an active layer -->

**Framework:**
- [Frontend framework] [version]
- [Meta-framework] [version] (if applicable)

**Key Packages:**
- [package-name] - [Purpose]
- [package-name] - [Purpose]

**State Management:**
- [State management approach per project — consult CLAUDE.md]

**Styling:**
- [Styling approach per project — consult CLAUDE.md]
- [Additional styling requirements]

### 3.3 Infrastructure
<!-- If infrastructure is an active layer -->

**Services:**
- [Database] [version]
- [Cache/Session store] [version] (if applicable)
- [Other services]

**Configuration:**
- [Environment variables]
- [Configuration files]

---

## 4. Architecture & Data Flow

### 4.1 Layer Assignments
<!-- If backend is an active layer -->

**Module Structure:**
```
[project-root]/src/
├── [layer-or-module-directory]/
│   ├── [module-name]/
│   │   ├── [service-name].service.ts
│   │   ├── [repository-name].repository.ts (if data access layer)
│   │   ├── dto/
│   │   └── interfaces/
```

**Layer Dependencies:**
<!-- Consult CLAUDE.md for layer dependency rules — dependencies should flow in one direction -->
[per project layer dependency rules — consult CLAUDE.md]
- Imports from: [Layer(s) this module can import from]
- Imported by: [Layer(s) that can import this module]

### 4.2 Data Flow Diagram

```
[User/Client]
    ↓
[Controller: API endpoint]
    ↓
[Guard: [Auth/access-control guards per CLAUDE.md]]
    ↓
[Service: Business logic]
    ↓
[Repository/External Service]
    ↓
[Database/External System]
    ↓
[Response → User]
```

<!-- Add detailed flow for complex features -->
**Detailed Flow:**
1. [Step 1 description]
2. [Step 2 description]
3. [Step 3 description]

### 4.3 API Contracts
<!-- If backend is an active layer -->

#### Endpoint: [Endpoint Name]

**HTTP Method & Path:**
```
[POST|GET|PUT|DELETE] /api/[path]
```

**Authentication:**
- [ ] [Session guard] required
- [ ] [Access control guard] - Role: [per project roles]
- [ ] [Resource guard] (if applicable)

**Request:**
```typescript
interface [RequestDtoName] {
  [field1]: [type]; // [Description]
  [field2]: [type]; // [Description]
  [field3]?: [type]; // [Optional field description]
}
```

**Response (Success):**
```typescript
interface [ResponseDtoName] {
  success: true;
  data: {
    [field1]: [type]; // [Description]
    [field2]: [type]; // [Description]
  };
}
```

**Response (Error):**
```typescript
interface ErrorResponse {
  success: false;
  error: {
    code: '[ERROR_CODE]';
    message: string; // [Localized user-facing message]
    details?: Record<string, unknown>;
  };
}
```

**Error Codes:**
| Code | HTTP Status | Description | User Message |
|------|-------------|-------------|--------------|
| `[ERROR_CODE_1]` | [4XX/5XX] | [Technical description] | [User-facing message] |
| `[ERROR_CODE_2]` | [4XX/5XX] | [Technical description] | [User-facing message] |

<!-- Repeat for each endpoint -->

### 4.4 Data Models
<!-- For features requiring database changes -->

**Schema Changes:**

```
// Add to schema file
// Syntax and format depend on your ORM/data layer — consult CLAUDE.md

model [ModelName] {
  id            String   @id @default(generated)

  // Data isolation (if multi-tenancy applies)
  // [isolationKeyField]  String
  // [relation to parent]

  // Feature fields
  [field1]      [Type]
  [field2]      [Type]

  // Timestamps
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  // Indexes
  @@index([relevant fields])
}
```

**Migration Strategy:**
- [ ] Migration file: `[migration-name]`
- [ ] Data seeding required: [Yes/No]
- [ ] Backward compatibility: [Yes/No - explain if No]

**Relationships:**
- `[ModelName]` → `[RelatedModel]`: [Relationship type and description]

### 4.5 UI Components
<!-- If frontend is an active layer -->

**Page Structure:**
```
[project-root]/src/routes/[route-path]/
├── [main-page-file]         # Main page component
├── [server-data-file]       # Server-side data loading (if applicable)
└── components/
    ├── [Component1]
    └── [Component2]
```

**Component Hierarchy:**
```
[PageComponent]
  ├── [ChildComponent1]
  │   └── [GrandchildComponent]
  └── [ChildComponent2]
```

**State Management:**
```typescript
// [State management approach per project — consult CLAUDE.md]
// Example: global state file, store, context, etc.
export let [stateName] = [state initialization per project pattern];
export function [actionName]() {
  // State mutation logic
}
```

**Assets Required:**
<!-- Consult CLAUDE.md for asset management conventions (icons, images, etc.) -->
- [Icon system per project — consult CLAUDE.md]
- `[AssetName]` - [Usage description]

---

## 5. Functional Requirements

<!-- Organize by priority: P0 (must-have), P1 (should-have), P2 (nice-to-have) -->

### FR-1: [Requirement Name] (P0)

**User Story:**
```
As a [user role]
I want [feature/capability]
So that [business value/benefit]
```

**Acceptance Criteria:**
- [ ] [Specific, testable criterion 1]
- [ ] [Specific, testable criterion 2]
- [ ] [Specific, testable criterion 3]

**Implementation Notes:**
- File path: `[path-to-file]`
- Existing utilities: `[utility-function()]` from `[file-path]`
- Dependencies: [List any module dependencies]

**Edge Cases:**

| Scenario | Expected Behavior |
|----------|-------------------|
| [Edge case 1] | [How system should respond] |
| [Edge case 2] | [How system should respond] |
| [Edge case 3] | [How system should respond] |

**Test Cases:**

**Unit Tests:**
```typescript
describe('[ComponentName]', () => {
  it('should [expected behavior]', () => {
    // Arrange
    [Setup test data and mocks]

    // Act
    [Execute the function/method]

    // Assert
    [Verify expected outcome]
  });
});
```

**Integration Tests:**
- [ ] Test: [Integration test description]
  - Setup: [Required state/data]
  - Action: [What to execute]
  - Expected: [Expected outcome]

**E2E Tests:**
- [ ] Test: [E2E test description]
  - User flow: [Step-by-step user actions]
  - Expected: [Expected final state]

**Defense-in-Depth Validation:**

| Layer | Validation Rules |
|-------|------------------|
| **Frontend** | [Client-side validation: required fields, format, length] |
| **Controller** | [DTO validation: [validation library decorators/schemas per project], sanitization] |
| **Business** | [Business rules: permissions, state transitions, constraints] |
| **Domain** | [Domain invariants: data integrity, consistency] |

<!-- Repeat for each functional requirement, incrementing FR-X: FR-2, FR-3, etc. -->

---

## 6. Non-Functional Requirements

<!-- NFR-X numbering is sequential across all subsections. Number continuously from NFR-1 through the final requirement. Actual counts will vary per feature. -->

### 6.1 Performance

#### NFR-1: Response Time Targets (P0)
- p50: [X ms]
- p95: [Y ms]
- p99: [Z ms]

#### NFR-2: Throughput (P1)
- Expected concurrent users: [N]
- Requests per second: [RPS]

#### NFR-3: Database Optimization (P0)
- Max queries per request: [N]
- Required indexes: [List indexes]
- Query complexity: [O(n), O(log n), etc.]

#### NFR-4: Caching Strategy (P1)
- [ ] Caching for [data type] using [cache solution per project]
- TTL: [duration]
- Cache invalidation: [trigger conditions]

### 6.2 Security

#### NFR-5: Authentication (P0)
- [ ] [Auth provider] session validation
- [ ] Session refresh handling
- [ ] Logout/session cleanup

#### NFR-6: Authorization — RBAC Matrix (P0)

| Action | [Role 1] | [Role 2] | [Role 3] | [Role 4] |
|--------|----------|----------|----------|----------|
| [Action 1] | ✓ | ✓ | ✗ | ✗ |
| [Action 2] | ✓ | ✓ | ✓ | ✗ |
| [Action 3] | ✓ | ✗ | ✗ | ✗ |

#### NFR-7: Input Validation (P0)
- [ ] Whitelist allowed characters
- [ ] Max length validation
- [ ] Type validation
- [ ] SQL injection prevention ([ORM] parameterized queries)
- [ ] XSS prevention (sanitize HTML if applicable)

#### NFR-8: Rate Limiting (P1)
- Endpoint: [endpoint-path]
- Limit: [N requests per M seconds]
- Scope: [per-user | per-IP | per-organization]

#### NFR-9: Sensitive Data Handling (P0)
- [ ] No passwords/tokens in logs
- [ ] PII encrypted at rest (if applicable)
- [ ] Secure file uploads (if applicable)

### 6.3 Accessibility

#### NFR-10: WCAG Compliance (P0)
- Level: [A | AA | AAA]

#### NFR-11: Keyboard Navigation (P0)
- [ ] All interactive elements accessible via Tab
- [ ] Focus indicators visible
- [ ] Skip links for main content

#### NFR-12: Screen Reader Support (P0)
- [ ] ARIA labels on custom components
- [ ] Semantic HTML elements
- [ ] Alternative text for images/icons

#### NFR-13: Color Contrast (P0)
- [ ] Text contrast ratio ≥ 4.5:1 (normal text)
- [ ] Text contrast ratio ≥ 3:1 (large text)

### 6.4 Scalability

#### NFR-14: Expected Load (P1)
- Initial: [N users, M requests/day]
- 6 months: [Projected growth]
- 12 months: [Projected growth]

#### NFR-15: Data Growth (P1)
- Records per month: [N]
- Storage per month: [X GB/TB]
- Retention policy: [Duration]

#### NFR-16: Horizontal Scaling (P2)
- [ ] Stateless design (session in external store, not memory)
- [ ] Database connection pooling
- [ ] Background job processing (if applicable)

### 6.5 Localization / i18n
<!-- Conditional: Include this section if the project has localization requirements. Consult CLAUDE.md for specifics. Remove this section if not applicable. -->

#### NFR-17: Text Normalization (P0)
- [ ] Apply project-specific text normalization to all user input
- [ ] Handle bidirectional text (if applicable)
- [ ] Handle mixed-script text (if applicable)

#### NFR-18: Display (P0)
- [ ] RTL/LTR layout using CSS logical properties (`inline-start`, `inline-end`) (if applicable)
- [ ] Correct text direction attributes
- [ ] Locale-specific date/time/currency formatting

#### NFR-19: Data Extraction (P1)
<!-- If applicable -->
- [ ] Locale-aware regex patterns for validation
- [ ] Locale-specific currency/number extraction

---

## 7. Boundaries

<!-- Critical: Define what AI should never do without approval -->

### 7.1 ALWAYS (Safe Assumptions)

<!-- AI can proceed without asking. Consult CLAUDE.md for project conventions. -->

- [X] Follow project conventions from CLAUDE.md for:
  - [Error handling pattern]
  - [Auth/access-control decorators or guards]
  - [Frontend framework syntax and conventions]
  - [Asset management (icons, images, etc.)]
  - [Styling approach]
  - [Testing patterns]
- [X] Use existing utilities documented in CLAUDE.md before creating new ones
- [X] Write unit tests following AAA pattern
- [Additional safe assumptions for this feature]

### 7.2 ASK FIRST (Requires Approval)

<!-- AI must ask before proceeding -->

- [ ] Adding new environment variables
- [ ] Changing [ORM] schema (database structure)
- [ ] Adding new packages/dependencies
- [ ] Modifying authentication/authorization logic
- [ ] Changing global guards or middleware
- [ ] [Billing/resource-guard logic] (if applicable)
- [ ] Creating new infrastructure components
- [ ] [Additional items requiring approval for this feature]

### 7.3 NEVER (Hard Stops)

<!-- AI must never do these. Consult CLAUDE.md for project-specific anti-patterns. -->

- ✗ Throw exceptions from service methods (use [error handling pattern per CLAUDE.md])
- ✗ Use legacy framework syntax (consult CLAUDE.md for current patterns)
- ✗ Use `console.log` in production code (use proper logging)
- ✗ Skip access-control checks on protected endpoints
- ✗ Hardcode colors/spacing (use project styling conventions)
- ✗ Use `any` type in TypeScript
- ✗ Create database queries without proper data isolation scope (if applicable)
- ✗ Store sensitive data in logs
- ✗ [Additional hard stops for this feature]

---

## 8. Commands

<!-- Consult DEVELOPMENT.md or project CLAUDE.md for development, testing, and database commands. Include feature-specific commands below. -->

### 8.1 Development & Database Commands

Refer to the project's DEVELOPMENT.md or CLAUDE.md for standard development, build, lint, and database commands.

### 8.2 Testing This Feature

```bash
# Run feature-specific tests
[command to run specific test file(s)]

# Example patterns:
# npm run test -- [test-file-name]
# pytest [test-file-name]
# go test ./[package]/...
```

---

## 9. References

### 9.1 File Paths to Study

<!-- List files discovered during codebase exploration that are relevant to this feature. Use project-relative paths. -->

**Backend:**
- `[project-root]/[path/to/relevant-file]` - [What to learn from this file]
- `[project-root]/[path/to/relevant-file]` - [What to learn from this file]

**Frontend:**
- `[project-root]/[path/to/relevant-file]` - [What to learn from this file]
- `[project-root]/[path/to/relevant-file]` - [What to learn from this file]

**Shared:**
- `[project-root]/[path/to/relevant-file]` - [What to learn from this file]

### 9.2 Related Documentation

<!-- Links to other relevant specs or documentation -->

- `[project-root]/[architecture-doc]` - Architecture and layer dependency rules
- `[project-root]/[development-doc]` - Environment setup and commands
- `[project-root]/[other-docs]` - [Description]
- `[Related spec file]` - [Relationship to this spec]

### 9.3 BDD Specifications

<!-- Link to Cucumber/Gherkin specs if they exist -->

- Feature file: `[path-to-feature.feature]`
- Step definitions: `[path-to-step-definitions]`

---

## 10. Implementation Checklist

<!-- High-level checklist for AI to track implementation -->

### Phase 1: Setup
- [ ] Create module structure
- [ ] Set up [ORM] schema changes (if needed)
- [ ] Run migrations
- [ ] Add new dependencies (if approved)

### Phase 2: Backend Implementation
- [ ] Create DTOs with validation
- [ ] Implement data access layer
- [ ] Implement business logic layer
- [ ] Implement orchestration layer (if needed)
- [ ] Create API controllers with guards
- [ ] Write unit tests
- [ ] Write integration tests

### Phase 3: Frontend Implementation
- [ ] Create page/route structure
- [ ] Build UI components
- [ ] Implement state management
- [ ] [Add assets per project conventions]
- [ ] [Style per project conventions]
- [ ] Write component tests

### Phase 4: Integration & Testing
- [ ] Test API endpoints manually
- [ ] Run E2E tests
- [ ] Test localization (if applicable)
- [ ] Test data isolation (if applicable)
- [ ] Test RBAC enforcement
- [ ] Performance testing

### Phase 5: Documentation & Cleanup
- [ ] Update API documentation
- [ ] Add inline code comments
- [ ] Update README files (if needed)
- [ ] Remove debug code/console.logs
- [ ] Final lint and format

---

## 11. Open Questions

<!-- Track unresolved questions that need product/technical decisions -->

1. [Question 1 that needs clarification]
   - Options: [A, B, C]
   - Recommended: [Option with reasoning]

2. [Question 2 that needs clarification]
   - Options: [A, B, C]
   - Recommended: [Option with reasoning]

---

## 12. Change Log

<!-- Track major changes to this spec -->

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| [YYYY-MM-DD] | 1.0.0 | [Name] | Initial draft |
| [YYYY-MM-DD] | 1.1.0 | [Name] | [Description of changes] |

---

## Appendix A: Glossary

<!-- Define domain-specific terms -->

| Term | Definition |
|------|------------|
| [Term 1] | [Definition] |
| [Term 2] | [Definition] |

---

## Appendix B: Wireframes/Mockups

<!-- For frontend features, include or link to designs -->

[Link to design tool or embed images]

---

<!--
End of SRS Template

Instructions for AI:
1. Replace ALL [placeholders] with actual values
2. Remove sections not relevant to the feature's active layers (backend/frontend/infrastructure)
3. Remove HTML comments before finalizing
4. Ensure all file paths use project-relative paths
5. Verify all requirements have acceptance criteria and test cases
6. Confirm Defense-in-Depth validation is specified for all inputs
7. Check if localization requirements apply (per CLAUDE.md)
8. Verify data isolation constraints (if applicable)
9. Ensure RBAC matrix is complete for all protected actions
10. Validate that error messages follow project localization requirements
-->
