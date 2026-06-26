# BDD Specification Template

This guide describes how to write BDD specifications for the current project. Each feature requires two files:

1. **CONTEXT.md** - Technical mapping and domain language
2. **[feature-name].feature** - Gherkin scenarios in business language

---

## CONTEXT.md Template

Every feature directory must contain a `CONTEXT.md` file that bridges business language and technical implementation.

```markdown
# [Feature Name] — BDD Context

## Domain Language

Define business terms in plain language and map them to technical entities.

| Term | Definition | Technical Mapping |
|------|-----------|-------------------|
| [Business Term] | [Plain language definition] | [Code entity: class, table, enum, constant] |

**Example:**
| Term | Definition | Technical Mapping |
|------|-----------|-------------------|
| User | A registered person in the system | `User` (database model) |
| Subscription | A user's active plan | `subscriptions` table |
| Task | A unit of work assigned to a user | `Task` entity |

## Actors

Define who can perform actions in this feature.

| Actor | Description | Permissions |
|-------|-------------|-------------|
| [Actor name] | [Who they are] | [What they can do in this feature] |

**Example:**
| Actor | Description | Permissions |
|-------|-------------|-------------|
| Admin | User with administrative privileges | Create users, manage settings, view all records |
| Member | Regular user in the system | Create and view own records |
| Viewer | Read-only user | View shared records |

## Technical Context

Map the feature to the codebase architecture.

- **Architecture Layer**: [Per project architecture documentation]
- **Key Files**:
  - `[project-root]/[path]` — [description]
- **Existing Utilities** (check before creating new ones):
  - `[utility function]` from `[path]` — [what it does]
- **Database Models**: [Models involved]
- **Dependencies**: [Services/modules this feature depends on]

**Example:**
- **Architecture Layer**: Domain / Business Logic
- **Key Files**:
  - `[project-root]/backend/src/domain/tasks/tasks.service.ts` — Core task logic
  - `[project-root]/backend/src/api/tasks/tasks.controller.ts` — HTTP endpoints
- **Existing Utilities**:
  - `validateInput()` from `shared/utils/validation.ts` — Sanitizes and validates user input
  - `formatDate()` from `shared/utils/dateUtils.ts` — Formats dates per locale settings
- **Database Models**: `Task`, `User`, `Project`
- **Dependencies**: `NotificationService`, `FileStorageService`, `AuthService`

## Implementation Mapping

Map Gherkin steps to actual code.

| Step | Code Equivalent |
|------|----------------|
| Given [precondition] | [Setup code / test fixture / database seed] |
| When [action] | [Service method / API call / controller endpoint] |
| Then [outcome] | [Assertion / DB query / result pattern check] |

**Example:**
| Step | Code Equivalent |
|------|----------------|
| Given project "Acme Corp" has 5 open tasks | `await createProject({ name: 'Acme Corp', tasks: 5 })` |
| When user assigns a task to team member | `POST /api/tasks/:id/assign` with user ID |
| Then the task is assigned successfully | `result.success === true` and task record updated in DB |
| Then the assignee receives a notification | `await notificationService.getLatest(userId)` returns assignment notification |

## Data Fixtures

Define reusable test data.

**Test Users:**
```typescript
{
  name: 'Alice Johnson',
  email: 'alice@example.com',
  role: 'ADMIN'
}
```

**Test Documents:**
- **Valid document**: `test-fixtures/sample-valid.pdf`
- **Invalid document**: `test-fixtures/sample-invalid.pdf`
- **Oversized file**: `test-fixtures/oversized.pdf`

**Sample Data:**
- User name: "Bob Smith"
- Project name: "Q1 Launch"
- Due date: "2026-03-15"

**Edge Cases:**
- Empty quota: `{ quota: 0 }`
- Maximum file size: 25MB
- Special characters in names: `O'Brien`, `José García`

## Error Codes Reference

Document all error codes with user-facing messages.

| Code | User Message | Scenario |
|------|-------------|----------|
| [ERR_XXX] | [Localized error text] | [When this error occurs] |

**Example:**
| Code | User Message | Scenario |
|------|-------------|----------|
| ERR_INSUFFICIENT_QUOTA | [localized message] | User quota < required amount |
| ERR_INVALID_FILE | [localized message] | Uploaded file is corrupted or unsupported |
| ERR_UNAUTHORIZED | [localized message] | User lacks required permissions |
| ERR_FILE_TOO_LARGE | [localized message] | File size exceeds maximum allowed |
```

---

## .feature File Template

Gherkin scenarios use business language and follow strict quality rules.

### File Structure

```gherkin
@domain:[module-name] @priority:P0 @layer:[architecture-layer]
Feature: [Feature Name in Business Terms]
  As a [actor]
  I want [capability]
  So that [business value]

  Background:
    Given [common setup that applies to all scenarios]
    And [additional context]

  @happy-path
  Scenario: [Descriptive name for successful case]
    Given [precondition with concrete data]
    And [additional precondition]
    When [action with specific values]
    Then [expected outcome with measurable result]
    And [additional verification]

  @edge-case
  Scenario: [Descriptive name for boundary condition]
    Given [edge case setup]
    When [action at boundary]
    Then [expected edge case behavior]

  @error-handling
  Scenario: [Descriptive name for error case]
    Given [error condition setup]
    When [action that triggers error]
    Then the operation fails with error code "[ERR_CODE]"
    And the error message is "[localized error message]"

  # Add project-specific tags as needed (e.g., @i18n, @rtl, @multi-tenancy)

  @defense-in-depth
  Scenario Outline: [Validation at multiple layers]
    Given [setup]
    When [action with <invalid_input>]
    Then [rejection at appropriate layer]

    Examples:
      | invalid_input | expected_error |
      | [value 1]     | [error 1]      |
      | [value 2]     | [error 2]      |
```

### Tag System

**Required Tags:**
- `@domain:[module]` - Maps to project module (e.g., @domain:users, @domain:billing)
- `@priority:P0|P1|P2` - P0 = critical, P1 = important, P2 = nice-to-have
- `@layer:[architecture-layer]` - Per project architecture documentation

**Scenario Tags:**
- `@happy-path` - Expected successful flows
- `@edge-case` - Boundary conditions, limits, unusual but valid cases
- `@error-handling` - Failure scenarios, validation errors
- `@defense-in-depth` - Validation across multiple layers

Add project-specific tags as needed (e.g., `@i18n`, `@rtl`, `@multi-tenancy`, `@performance`).

### Quality Rules

#### 1. Business Language Over Technical Jargon

**Bad:**
```gherkin
When the user POSTs to /api/documents with a PDF blob
Then the HTTP status code is 201
```

**Good:**
```gherkin
When the user uploads a document
Then the document is accepted for processing
```

#### 2. One Behavior Per Scenario

**Bad:**
```gherkin
Scenario: User uploads document and views it and deletes it
```

**Good:**
```gherkin
Scenario: User uploads a valid document
Scenario: User views their uploaded documents
Scenario: User deletes their own document
```

#### 3. Concrete Examples with Real Data

**Bad:**
```gherkin
Given a user has some quota
When the user uploads several documents
```

**Good:**
```gherkin
Given user "Alice Johnson" has 10 quota remaining
When the user uploads 3 documents
```

#### 4. Localized Error Messages in All Error Scenarios

If the project uses localization, error messages must be in the project's required language.

```gherkin
@error-handling
Scenario: Upload fails when user has no quota
  Given user "Bob Smith" has 0 quota remaining
  When the user attempts to upload a document
  Then the operation fails with error code "ERR_INSUFFICIENT_QUOTA"
  And the error message is "[localized error message]"
```

#### 5. Tables for Multi-Field Data

**Good:**
```gherkin
Given the following users exist:
  | name           | quota | tier     |
  | Alice Johnson  | 100   | PREMIUM  |
  | Bob Smith      | 10    | BASIC    |
  | Carol Davis    | 0     | TRIAL    |
```

#### 6. Scenario Outlines for Parameterized Validation

**Good:**
```gherkin
@defense-in-depth
Scenario Outline: Reject invalid file types
  Given user "Alice Johnson" has 10 quota remaining
  When the user uploads a file with extension "<extension>"
  Then the operation fails with error code "ERR_INVALID_FILE_TYPE"
  And the error message is "[localized error message]"

  Examples:
    | extension |
    | .docx     |
    | .jpg      |
    | .txt      |
    | .exe      |
```

#### 7. Measurable Outcomes

**Bad:**
```gherkin
Then the task is processed
```

**Good:**
```gherkin
Then the task status is "COMPLETED"
And the task is assigned to "Bob Smith"
And the user has 9 quota remaining
```

---

## Complete Example

### CONTEXT.md

```markdown
# Task Assignment — BDD Context

## Domain Language

| Term | Definition | Technical Mapping |
|------|-----------|-------------------|
| Task | A unit of work with a title, status, and assignee | `Task` (database model) |
| Project | A collection of related tasks | `Project` (database model) |
| Assignment | Linking a task to a team member | `task.assigneeId` field |

## Actors

| Actor | Description | Permissions |
|-------|-------------|-------------|
| Team Lead | Manager of a project | Create tasks, assign members, view all project tasks |
| Member | Regular team member | View assigned tasks, update task status |

## Technical Context

- **Architecture Layer**: Domain / Business Logic
- **Key Files**:
  - `[project-root]/backend/src/domain/tasks/tasks.service.ts` — Task CRUD and assignment logic
  - `[project-root]/backend/src/api/tasks/tasks.controller.ts` — HTTP endpoints
- **Existing Utilities**:
  - `validateInput()` from `shared/utils/validation.ts` — Input sanitization
  - `formatDate()` from `shared/utils/dateUtils.ts` — Locale-aware date formatting
- **Database Models**: `Task`, `Project`, `User`
- **Dependencies**: `NotificationService`, `AuthService`

## Implementation Mapping

| Step | Code Equivalent |
|------|----------------|
| Given project "Acme" has 5 tasks | `await createProject({ name: 'Acme', tasks: 5 })` |
| When team lead assigns a task | `POST /api/tasks/:id/assign` with `{ assigneeId }` |
| Then the task is assigned | `result.success === true` and `task.assigneeId` updated |
| Then the assignee is notified | `notificationService.getLatest(userId)` returns notification |

## Data Fixtures

**Test Users:**
```typescript
{ name: 'Alice Johnson', email: 'alice@example.com', role: 'TEAM_LEAD' }
{ name: 'Bob Smith', email: 'bob@example.com', role: 'MEMBER' }
```

**Test Project:** `{ name: 'Q1 Launch', status: 'ACTIVE', taskCount: 5 }`

## Error Codes Reference

| Code | User Message | Scenario |
|------|-------------|----------|
| ERR_USER_NOT_FOUND | [localized message] | Assignee does not exist |
| ERR_FORBIDDEN | [localized message] | User lacks permission to assign tasks |
```

### assign-task.feature

```gherkin
@domain:tasks @priority:P0 @layer:domain
Feature: Assign Task to Team Member
  As a team lead
  I want to assign tasks to team members
  So that work is distributed and tracked

  Background:
    Given project "Q1 Launch" exists with status "ACTIVE"
    And user "Alice Johnson" is a team lead of project "Q1 Launch"

  @happy-path
  Scenario: Successfully assign a task to a team member
    Given user "Bob Smith" is a member of project "Q1 Launch"
    And task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Alice Johnson" assigns task "Design homepage" to "Bob Smith"
    Then the task status is "ASSIGNED"
    And the task assignee is "Bob Smith"
    And user "Bob Smith" receives a notification about the assignment

  @error-handling
  Scenario: Reject assignment to a non-existent user
    Given task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Alice Johnson" assigns task "Design homepage" to a non-existent user
    Then the operation fails with error code "ERR_USER_NOT_FOUND"
    And the error message is "[localized message]"
    And the task remains unassigned

  @error-handling
  Scenario: Reject assignment by unauthorized user
    Given user "Bob Smith" is a member of project "Q1 Launch"
    And task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Bob Smith" attempts to assign task "Design homepage" to another member
    Then the operation fails with error code "ERR_FORBIDDEN"
    And the error message is "[localized message]"

  @defense-in-depth
  Scenario Outline: Reject invalid task IDs at validation layer
    When user "Alice Johnson" assigns a task with ID "<invalid_id>" to "Bob Smith"
    Then the operation fails with error code "<expected_error>"

    Examples:
      | invalid_id       | expected_error       |
      | null             | ERR_INVALID_INPUT    |
      | -1               | ERR_INVALID_INPUT    |
      | non-existent-id  | ERR_TASK_NOT_FOUND   |

  @edge-case
  Scenario: Reassign an already-assigned task
    Given user "Bob Smith" is a member of project "Q1 Launch"
    And user "Carol Davis" is a member of project "Q1 Launch"
    And task "Design homepage" is assigned to "Bob Smith"
    When user "Alice Johnson" reassigns task "Design homepage" to "Carol Davis"
    Then the task assignee is "Carol Davis"
    And user "Carol Davis" receives a notification about the assignment
    And user "Bob Smith" receives a notification about the reassignment
```

---

## Writing Process

1. **Read project documentation** - Understand project principles and conventions
2. **Check existing code** - Search for similar features and reusable utilities
3. **Write CONTEXT.md** - Map business language to technical implementation
4. **Write .feature file** - Use business language, concrete examples, localized errors
5. **Review against quality rules** - Ensure all scenarios follow the template

## Common Mistakes to Avoid

- Using technical language in scenarios (HTTP codes, function names)
- Vague quantities ("some", "several", "a few")
- Missing localized error messages in error scenarios (if project requires localization)
- Testing multiple behaviors in one scenario
- Forgetting data isolation checks (if project uses multi-tenancy)
- Skipping defense-in-depth validation at multiple layers
- Not checking for existing utilities before planning new code
