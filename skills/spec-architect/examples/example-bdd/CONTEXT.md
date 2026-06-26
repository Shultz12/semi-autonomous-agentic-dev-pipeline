# Task Assignment — BDD Context

## Domain Language
| Term | Definition | Technical Mapping |
|------|-----------|-------------------|
| Task | A unit of work with a title, status, and optional assignee | `Task` (database model) |
| Project | A collection of related tasks owned by a team | `Project` (database model) |
| Assignment | Linking a task to a specific team member | `task.assigneeId` field update |
| Status Transition | Moving a task from one status to another | `TaskStatus` enum: OPEN, ASSIGNED, IN_PROGRESS, COMPLETED |
| Team Lead | A project member with management permissions | `ProjectMembership` with role `TEAM_LEAD` |

## Actors
| Actor | Description | Permissions |
|-------|-------------|-------------|
| Team Lead | Manager of a project | Assign/reassign tasks, update any task status, view all project tasks |
| Member | Regular team member | View assigned tasks, update own task status |
| Viewer | Read-only project participant | View project tasks |

## Technical Context
- Architecture Layer: Domain / Business Logic (consult CLAUDE.md for specific layer naming)
- Key Files (use actual paths from codebase exploration):
  - `[project-root]/[domain-layer]/tasks/tasks.service.ts` — Task CRUD and assignment logic
  - `[project-root]/[api-layer]/tasks/tasks.controller.ts` — HTTP endpoints with auth guards
  - `[project-root]/[domain-layer]/notifications/notifications.service.ts` — Assignment notifications
  - `[project-root]/[shared-utils]/validation.ts` — Input sanitization
  - `[project-root]/[shared-utils]/[error-handling]` — Result/error pattern (consult CLAUDE.md)
- Existing Utilities: [validation utility], [date formatting utility], [error handling pattern] — consult CLAUDE.md
- Database Models: Task (status enum), Project, User, ProjectMembership

## Implementation Mapping
| Step | Code Equivalent |
|------|----------------|
| Given project "Q1 Launch" exists with 5 tasks | Seed Project with name and 5 Task records |
| Given user "Alice" is a team lead of project | Create User + ProjectMembership with role TEAM_LEAD |
| When the team lead assigns a task to a member | PUT /api/tasks/:taskId/assign with { assigneeId } |
| Then the task is assigned | Assert Task record updated: assigneeId set, status = ASSIGNED |
| Then the assignee receives a notification | Assert Notification record created for assignee |
| Then the operation fails with error | Assert error result with matching error code |

## Data Fixtures
- Test Project: { id: "proj-test-001", name: "Q1 Launch", status: "ACTIVE" }
- Team Lead: { id: "user-001", name: "Alice Johnson", email: "alice@example.com", role: "TEAM_LEAD" }
- Team Member: { id: "user-002", name: "Bob Smith", email: "bob@example.com", role: "MEMBER" }
- Test Task: { id: "task-001", title: "Design homepage", status: "OPEN", projectId: "proj-test-001" }

## Error Codes Reference
| Code | User Message | Scenario |
|------|-------------|----------|
| ERR_TASK_NOT_FOUND | [localized message] | Task does not exist |
| ERR_USER_NOT_FOUND | [localized message] | Assignee does not exist |
| ERR_NOT_PROJECT_MEMBER | [localized message] | Assignee is not a member of the project |
| ERR_FORBIDDEN | [localized message] | User lacks team lead role |
| ERR_INVALID_INPUT | [localized message] | Missing or malformed input |
| ERR_TASK_COMPLETED | [localized message] | Cannot assign a completed task |
