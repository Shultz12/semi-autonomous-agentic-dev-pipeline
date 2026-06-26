---
version: "1.0.0"
status: draft
project: "[project-name]"
feature: "task-assignment"
active-layers: [backend, frontend]
related-specs: ["features/task-management.feature"]
created: "2026-01-20"
updated: "2026-01-20"
---

# Software Requirements Specification: Task Assignment & Tracking

## 1. Objective

### 1.1 Goal

Enable team leads to assign tasks to team members within projects, with status tracking, notifications, and access control.

### 1.2 Success Criteria

- [ ] Team lead can assign any unassigned task to a project member
- [ ] Assigned member receives a notification
- [ ] Task status transitions are enforced (OPEN -> ASSIGNED -> IN_PROGRESS -> COMPLETED)
- [ ] Only authorized users (team leads) can assign/reassign tasks
- [ ] All task operations are scoped to the user's project

## 2. Context & Constraints

### Business Context

**Problem Statement:**
Teams lack a structured way to distribute work. Tasks are assigned informally via chat or email, leading to lost assignments, duplicated effort, and no visibility into workload distribution.

**Business Value:**
Centralized task assignment gives team leads a clear view of workload and enables members to see their responsibilities in one place.

**User Impact:**
Team leads can assign and reassign tasks. Members see their assignments and update progress. All users gain visibility into project status.

### Technical Context

**Architecture Layer:**
- Layer/Module: [per project architecture — consult CLAUDE.md]
- Primary module: `tasks` (domain/business logic)
- Supporting module: `notifications` (side-effect on assignment)

**Related Modules:**
- `projects` - Tasks belong to a project; project membership determines access
- `users` - Assignees must be valid project members
- `notifications` - Sends assignment/reassignment alerts

**Existing Utilities:**
- `[validation-utility]` - Input sanitization (consult CLAUDE.md)
- `[date-utility]` - Locale-aware date formatting (consult CLAUDE.md)
- `[error-handling-pattern]` - Standardized result/error responses (consult CLAUDE.md)

**Dependencies:**
- [ORM] - Database operations
- [Notification service] - Email or in-app notifications

### Constraints

#### Data Isolation

- [ ] All task queries scoped by `projectId`
- [ ] Access control: only project members can view/modify project tasks
- [ ] Session validation using [session guard per CLAUDE.md]

#### Performance

- Response time: p50: 100ms, p95: 300ms, p99: 500ms
- Database queries: Max 3 queries per request
- Notification dispatch: Async (does not block response)

#### Security

- [ ] Input validation at all layers (Frontend -> Controller -> Business -> Domain)
- [ ] No sensitive data in logs
- [ ] Rate limiting: 60 requests per minute per user

### Scope Boundaries

**In Scope:**
- Single task assignment to one team member
- Task reassignment (change assignee)
- Status tracking (OPEN, ASSIGNED, IN_PROGRESS, COMPLETED)
- Assignment and reassignment notifications
- Task listing with filters (by status, assignee, project)

**Out of Scope:**
- Bulk assignment (multiple tasks at once)
- Task dependencies (blocked-by relationships)
- Time tracking or effort estimation
- File attachments on tasks
- Recurring/scheduled tasks

## 3. Tech Stack

### 3.1 Backend

**Framework:**
- [Framework per CLAUDE.md]
- [ORM per CLAUDE.md]

**Key Packages:**
- [validation-library] - DTO and input validation
- [notification-library] - Async notification dispatch (if applicable)

**Patterns:**
- [Error handling pattern per CLAUDE.md] for all service methods
- [DI/module system per CLAUDE.md]

### 3.2 Frontend

**Framework:**
- [Frontend framework per CLAUDE.md]

**Key Packages:**
- [form-library] - Task assignment form handling (if applicable)

**State Management:**
- [State management approach per CLAUDE.md]

**Styling:**
- [Styling approach per CLAUDE.md]

## 4. Architecture & Data Flow

### 4.1 Layer Assignments

**Module Structure:**
```
[project-root]/src/
├── [domain-layer]/
│   └── tasks/
│       ├── tasks.service.ts
│       ├── dto/
│       │   ├── assign-task.dto.ts
│       │   └── task-response.dto.ts
│       └── interfaces/
│           └── task.interface.ts
├── [api-layer]/
│   └── tasks/
│       └── tasks.controller.ts
└── [notification-module]/
    └── notifications.service.ts
```

**Layer Dependencies:**
- `tasks` service imports from: [data access layer], [notification module]
- `tasks` controller imports from: [tasks service], [auth guards]
- Consult CLAUDE.md for layer dependency rules

### 4.2 Data Flow Diagram

```
1. Team Lead (Frontend)
   ↓
2. POST /api/tasks/:taskId/assign
   - [Session guard] validates session
   - [Access guard] checks project membership + team lead role
   ↓
3. TasksController
   - Validates AssignTaskDto
   - Calls TasksService.assignTask()
   ↓
4. TasksService (Business Logic)
   - Validates task exists and belongs to project
   - Validates assignee is a project member
   - Updates task record (assigneeId, status -> ASSIGNED)
   - Dispatches notification to assignee
   - Returns result
   ↓
5. Controller Response
   - Returns 200 OK with updated task
```

### 4.3 API Contracts

#### Endpoint: Assign Task

**HTTP Method & Path:**
```
PUT /api/tasks/:taskId/assign
```

**Authentication:**
- [ ] [Session guard] required
- [ ] [Access guard] - Role: TEAM_LEAD within the task's project

**Request:**
```typescript
interface AssignTaskDto {
  assigneeId: string; // User ID of the team member
}
```

**Response (Success):**
```typescript
interface TaskResponseDto {
  success: true;
  data: {
    id: string;
    title: string;
    status: 'ASSIGNED';
    assigneeId: string;
    assigneeName: string;
    projectId: string;
    updatedAt: string;
  };
}
```

**Response (Error):**
```typescript
interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string; // [Localized user-facing message]
  };
}
```

**Error Codes:**
| Code | HTTP Status | Description | User Message |
|------|-------------|-------------|--------------|
| `ERR_TASK_NOT_FOUND` | 404 | Task does not exist or is not in this project | [localized message] |
| `ERR_USER_NOT_FOUND` | 404 | Assignee does not exist | [localized message] |
| `ERR_NOT_PROJECT_MEMBER` | 400 | Assignee is not a member of the project | [localized message] |
| `ERR_FORBIDDEN` | 403 | User is not a team lead for this project | [localized message] |
| `ERR_INVALID_INPUT` | 400 | Missing or malformed assigneeId | [localized message] |
| `ERR_TASK_COMPLETED` | 400 | Cannot assign a task that is already completed | [localized message] |

#### Endpoint: List Tasks

**HTTP Method & Path:**
```
GET /api/projects/:projectId/tasks
```

**Authentication:**
- [ ] [Session guard] required
- [ ] [Access guard] - Role: any project member

**Query Parameters:**
```typescript
interface ListTasksQueryDto {
  status?: 'OPEN' | 'ASSIGNED' | 'IN_PROGRESS' | 'COMPLETED';
  assigneeId?: string;
  page?: number;   // Default: 1
  limit?: number;  // Default: 20, max: 100
}
```

**Response (Success):**
```typescript
interface TaskListResponseDto {
  success: true;
  data: {
    tasks: Array<{
      id: string;
      title: string;
      status: string;
      assigneeId: string | null;
      assigneeName: string | null;
      createdAt: string;
      updatedAt: string;
    }>;
    pagination: {
      total: number;
      page: number;
      limit: number;
      totalPages: number;
    };
  };
}
```

### 4.4 Data Models

**Schema Changes:**

```
// Syntax per project ORM — consult CLAUDE.md

model Task {
  id          String     @id @default(generated)
  title       String
  description String?
  status      TaskStatus @default(OPEN)
  projectId   String
  assigneeId  String?
  createdById String
  createdAt   DateTime   @default(now())
  updatedAt   DateTime   @updatedAt

  project     Project    @relation(fields: [projectId], references: [id])
  assignee    User?      @relation("TaskAssignee", fields: [assigneeId], references: [id])
  createdBy   User       @relation("TaskCreator", fields: [createdById], references: [id])

  @@index([projectId, status])
  @@index([assigneeId])
}

enum TaskStatus {
  OPEN
  ASSIGNED
  IN_PROGRESS
  COMPLETED
}
```

**Migration Strategy:**
- [ ] Migration file: `add-task-assignment-fields`
- [ ] Data seeding required: No (existing tasks default to OPEN with null assignee)
- [ ] Backward compatibility: Yes

**Relationships:**
- `Task` -> `Project`: Many-to-one (task belongs to one project)
- `Task` -> `User` (assignee): Many-to-one, nullable
- `Task` -> `User` (creator): Many-to-one

### 4.5 UI Components

**Page Structure:**
```
[project-root]/src/routes/projects/[projectId]/tasks/
├── [main-page]           # Task list view
├── [server-data]         # Load tasks for project
└── components/
    ├── TaskList           # Table/list of tasks with filters
    ├── TaskRow            # Single task row with assign action
    └── AssignTaskDialog   # Modal to select assignee
```

**Component Hierarchy:**
```
TasksPage
  ├── TaskFilters (status, assignee dropdown)
  ├── TaskList
  │   └── TaskRow (per task: title, status badge, assignee, assign button)
  └── AssignTaskDialog (member dropdown, confirm button)
```

**State Management:**
```typescript
// Per project state management approach — consult CLAUDE.md
// Manages task list, filters, and assignment dialog state

export let tasks = [state initialization per project pattern];
export let selectedTaskId = [state initialization per project pattern];

export function assignTask(taskId: string, assigneeId: string) {
  // API call -> update local state on success
}
```

## 5. Functional Requirements

### FR-1: Assign Task to Team Member (P0)

**User Story:**
```
As a team lead
I want to assign a task to a team member
So that work is distributed and each member knows their responsibilities
```

**Acceptance Criteria:**
- [ ] Team lead can select a project member from a dropdown and assign them to a task
- [ ] Task status changes from OPEN to ASSIGNED upon assignment
- [ ] Assignee receives a notification with task title and project name
- [ ] Task list updates to show the new assignee
- [ ] Only team leads of the task's project can perform assignment

**Implementation Notes:**
- Use [error handling pattern per CLAUDE.md] — never throw exceptions from service
- Validate assignee is an active member of the project before assignment
- Dispatch notification asynchronously (do not block the response)

**Edge Cases:**

| Scenario | Expected Behavior |
|----------|-------------------|
| Assign to self | Allowed — team lead can assign tasks to themselves |
| Assign completed task | Reject with ERR_TASK_COMPLETED |
| Assignee leaves project after assignment | Task remains assigned; handle in separate user-removal flow |
| Concurrent assignment by two team leads | Last-write-wins; both receive success (eventual consistency) |

**Test Cases:**

**Unit Tests:**
```typescript
describe('TasksService.assignTask', () => {
  it('should assign task to a valid project member', () => {
    // Arrange
    const task = createMockTask({ status: 'OPEN', projectId: 'proj-1' });
    const member = createMockUser({ id: 'user-2', projectIds: ['proj-1'] });

    // Act
    const result = await service.assignTask(task.id, member.id, teamLeadId);

    // Assert
    expect(result.success).toBe(true);
    expect(result.data.assigneeId).toBe(member.id);
    expect(result.data.status).toBe('ASSIGNED');
  });

  it('should reject assignment to non-project-member', () => {
    // Arrange
    const task = createMockTask({ status: 'OPEN', projectId: 'proj-1' });
    const outsider = createMockUser({ id: 'user-3', projectIds: ['proj-2'] });

    // Act
    const result = await service.assignTask(task.id, outsider.id, teamLeadId);

    // Assert
    expect(result.success).toBe(false);
    expect(result.error.code).toBe('ERR_NOT_PROJECT_MEMBER');
  });
});
```

**Integration Tests:**
- [ ] Test: Assign task via API endpoint
  - Setup: Create project, team lead, member, and task
  - Action: PUT /api/tasks/:taskId/assign with valid assigneeId
  - Expected: 200 OK, task updated in database, notification created

**E2E Tests:**
- [ ] Test: Full assignment flow from UI
  - User flow: Team lead opens task list -> clicks assign on a task -> selects member from dropdown -> confirms
  - Expected: Task row shows assignee name, status badge shows "Assigned"

**Defense-in-Depth Validation:**

| Layer | Validation Rules |
|-------|------------------|
| **Frontend** | Required field: assigneeId must be selected; dropdown only shows project members |
| **Controller** | DTO validation: assigneeId is a non-empty string, valid format |
| **Business** | Permission check: caller is team lead; assignee is project member; task is not completed |
| **Domain** | Data integrity: task exists, project exists, status transition is valid |

---

### FR-2: Reassign Task (P1)

**User Story:**
```
As a team lead
I want to reassign a task to a different team member
So that I can rebalance workload when priorities change
```

**Acceptance Criteria:**
- [ ] Team lead can change the assignee of an already-assigned task
- [ ] Previous assignee receives a "removed from task" notification
- [ ] New assignee receives an "assigned to task" notification
- [ ] Task status remains ASSIGNED (or IN_PROGRESS if already started)
- [ ] Reassignment is logged for audit purposes

**Edge Cases:**

| Scenario | Expected Behavior |
|----------|-------------------|
| Reassign to same person | No-op — return success without sending notifications |
| Reassign IN_PROGRESS task | Allowed; status stays IN_PROGRESS |
| Reassign COMPLETED task | Reject with ERR_TASK_COMPLETED |

---

### FR-3: List and Filter Tasks (P0)

**User Story:**
```
As a project member
I want to view tasks filtered by status and assignee
So that I can see what work needs attention
```

**Acceptance Criteria:**
- [ ] Any project member can view the task list for their project
- [ ] Tasks can be filtered by status (OPEN, ASSIGNED, IN_PROGRESS, COMPLETED)
- [ ] Tasks can be filtered by assignee
- [ ] Results are paginated (default 20 per page, max 100)
- [ ] Task list shows: title, status, assignee name, last updated date

**Implementation Notes:**
- Use efficient database queries with proper indexing on `(projectId, status)` and `(assigneeId)`
- Return assignee name via join/include — avoid N+1 queries

---

### FR-4: Update Task Status (P0)

**User Story:**
```
As a team member
I want to update the status of my assigned task
So that the team can track progress
```

**Acceptance Criteria:**
- [ ] Assignee can move task: ASSIGNED -> IN_PROGRESS -> COMPLETED
- [ ] Team lead can move any task to any valid status
- [ ] Invalid transitions are rejected (e.g., OPEN -> COMPLETED)
- [ ] Status change is timestamped

**Valid Status Transitions:**

| From | To | Who Can Perform |
|------|----|-----------------|
| OPEN | ASSIGNED | Team Lead (via assignment) |
| ASSIGNED | IN_PROGRESS | Assignee or Team Lead |
| IN_PROGRESS | COMPLETED | Assignee or Team Lead |
| ASSIGNED | OPEN | Team Lead (unassign) |
| IN_PROGRESS | ASSIGNED | Team Lead (revert) |

## 6. Non-Functional Requirements

### 6.1 Performance

#### NFR-1: Response Time Targets (P0)
- p50: 80ms
- p95: 250ms
- p99: 500ms

#### NFR-2: Throughput (P1)
- Expected concurrent users: 50
- Requests per second: 100

#### NFR-3: Database Optimization (P0)
- Max queries per request: 3
- Required indexes: `(projectId, status)`, `(assigneeId)`, `(projectId, assigneeId)`
- Pagination: Offset-based for simplicity (cursor-based if dataset grows large)

### 6.2 Security

#### NFR-4: Authentication (P0)
- [ ] [Auth provider per CLAUDE.md] session validation on all endpoints
- [ ] Session refresh handling

#### NFR-5: Authorization — RBAC Matrix (P0)

| Action | Team Lead | Member | Viewer |
|--------|-----------|--------|--------|
| Assign task | Yes | No | No |
| Reassign task | Yes | No | No |
| Update own task status | Yes | Yes | No |
| View project tasks | Yes | Yes | Yes |

#### NFR-6: Input Validation (P0)
- [ ] `assigneeId`: valid UUID/ID format
- [ ] `taskId`: valid UUID/ID format
- [ ] `status`: enum whitelist (OPEN, ASSIGNED, IN_PROGRESS, COMPLETED)
- [ ] `title`: max 200 characters, sanitized
- [ ] SQL injection prevention via parameterized queries

#### NFR-7: Rate Limiting (P1)
- Endpoint: `/api/tasks/*`
- Limit: 60 requests per minute
- Scope: per-user

### 6.3 Accessibility

#### NFR-8: WCAG Compliance (P0)
- Level: AA

#### NFR-9: Keyboard Navigation (P0)
- [ ] Task list rows navigable via Tab/Arrow keys
- [ ] Assign dialog accessible via keyboard
- [ ] Focus trapped within dialog when open

#### NFR-10: Screen Reader Support (P0)
- [ ] Task status announced as ARIA live region on change
- [ ] Assign button has descriptive ARIA label ("Assign task: [title]")

### 6.4 Scalability

#### NFR-11: Expected Load (P1)
- Initial: 50 users, 500 tasks/day
- 6 months: 200 users, 2000 tasks/day
- 12 months: 500 users, 5000 tasks/day

#### NFR-12: Data Growth (P1)
- Records per month: ~10,000 tasks
- Storage per month: Minimal (text-only records)
- Retention policy: Indefinite (completed tasks archived after 1 year)

## 7. Boundaries

### 7.1 ALWAYS (Safe Assumptions)

- [X] Follow project conventions from CLAUDE.md for:
  - Error handling pattern (result objects, not exceptions)
  - Auth/access-control guards
  - Frontend framework syntax
  - Styling approach
  - Testing patterns
- [X] Use existing utilities from CLAUDE.md before creating new ones
- [X] Write unit tests following AAA pattern
- [X] Scope all task queries by projectId
- [X] Validate status transitions against the allowed transition table

### 7.2 ASK FIRST (Requires Approval)

- [ ] Adding new database models or modifying schema
- [ ] Adding new packages/dependencies
- [ ] Modifying authentication or authorization logic
- [ ] Adding new notification channels (email, push, etc.)
- [ ] Creating new API endpoints beyond those specified
- [ ] Changing global middleware or guards

### 7.3 NEVER (Hard Stops)

- No throwing exceptions from service methods (use [error handling pattern per CLAUDE.md])
- No using legacy framework syntax (consult CLAUDE.md)
- No `console.log` in production code (use proper logging)
- No skipping access-control checks on protected endpoints
- No hardcoded colors/spacing (use project styling conventions)
- No `any` type in TypeScript
- No task queries without projectId scope
- No bypassing status transition rules

## 8. Commands

### 8.1 Development & Database Commands

Refer to the project's DEVELOPMENT.md or CLAUDE.md for standard development, build, lint, and database commands.

### 8.2 Testing This Feature

```bash
# Run task-related unit tests
[command per project] -- tasks.service.spec
[command per project] -- tasks.controller.spec

# Run task-related E2E tests
[command per project] -- tasks.e2e-spec
```

## 9. References

### 9.1 File Paths to Study

**Backend:**
- `[project-root]/[domain-layer]/tasks/` - Task service and business logic
- `[project-root]/[domain-layer]/notifications/` - Notification dispatch patterns
- `[project-root]/[api-layer]/tasks/` - Controller and route definitions
- `[project-root]/[shared-utils]/` - Validation, date formatting, error handling utilities

**Frontend:**
- `[project-root]/[routes]/projects/[projectId]/tasks/` - Task list page
- `[project-root]/[components]/` - Reusable UI components (dialogs, badges, tables)

**Shared:**
- `[project-root]/[shared-types]/` - Shared TypeScript interfaces and enums

### 9.2 Related Documentation

- `[project-root]/CLAUDE.md` - Project conventions and patterns
- `[project-root]/ARCHITECTURE.md` - Layer dependency rules
- `[project-root]/DEVELOPMENT.md` - Environment setup and commands

### 9.3 BDD Specifications

- Feature file: `.project/cycles/[date]-task-assignment/specs/task-management.feature`
- Context file: `.project/cycles/[date]-task-assignment/specs/CONTEXT.md`

## 10. Implementation Checklist

### Phase 1: Setup
- [ ] Create task module structure
- [ ] Set up schema changes (Task model, TaskStatus enum)
- [ ] Run migrations
- [ ] Verify indexes created

### Phase 2: Backend Implementation
- [ ] Create AssignTaskDto with validation
- [ ] Implement TasksService.assignTask()
- [ ] Implement TasksService.reassignTask()
- [ ] Implement TasksService.listTasks() with filters and pagination
- [ ] Implement TasksService.updateStatus() with transition validation
- [ ] Create TasksController with auth guards
- [ ] Write unit tests for all service methods
- [ ] Write integration tests for API endpoints

### Phase 3: Frontend Implementation
- [ ] Create tasks page with route
- [ ] Build TaskList component with filters
- [ ] Build AssignTaskDialog component
- [ ] Implement state management for task list
- [ ] Style per project conventions
- [ ] Write component tests

### Phase 4: Integration & Testing
- [ ] Test assignment flow end-to-end
- [ ] Test RBAC enforcement (team lead vs member vs viewer)
- [ ] Test status transition rules
- [ ] Test pagination and filtering
- [ ] Performance testing (response times under load)

### Phase 5: Documentation & Cleanup
- [ ] Update API documentation
- [ ] Remove debug code
- [ ] Final lint and format

## 11. Open Questions

1. Should completed tasks be auto-archived after a period?
   - Options: No archival, Archive after 30 days, Archive after 90 days
   - Recommended: Archive after 90 days (reduces active dataset size)

2. Should reassignment require a reason/comment?
   - Options: No reason required, Optional reason, Required reason
   - Recommended: Optional reason (low friction, but traceable when needed)

## 12. Change Log

| Date | Version | Author | Changes |
|------|---------|--------|---------|
| 2026-01-20 | 1.0.0 | Development Team | Initial draft |

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| Task | A unit of work within a project, with a title, status, and optional assignee |
| Project | A collection of tasks owned by a team |
| Assignment | The act of linking a task to a specific team member |
| Team Lead | A project member with permission to assign and manage tasks |
| Status Transition | A valid change from one task status to another |
