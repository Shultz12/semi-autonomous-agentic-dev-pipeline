@domain:tasks @priority:P0 @layer:domain
Feature: Task Assignment and Tracking
  As a team lead
  I want to assign tasks to team members
  So that work is distributed and tracked within the project

  Background:
    Given project "Q1 Launch" exists with status "ACTIVE"
    And user "Alice Johnson" is a team lead of project "Q1 Launch"
    And user "Bob Smith" is a member of project "Q1 Launch"

  @happy-path
  Scenario: Successfully assign a task to a team member
    Given task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Alice Johnson" assigns task "Design homepage" to "Bob Smith"
    Then the task status is "ASSIGNED"
    And the task assignee is "Bob Smith"
    And user "Bob Smith" receives a notification about the assignment

  @happy-path
  Scenario: Assignee updates task status to in progress
    Given task "Design homepage" is assigned to "Bob Smith" in project "Q1 Launch"
    When user "Bob Smith" updates task "Design homepage" status to "IN_PROGRESS"
    Then the task status is "IN_PROGRESS"
    And the status change is timestamped

  @happy-path
  Scenario: Assignee completes a task
    Given task "Design homepage" has status "IN_PROGRESS" and is assigned to "Bob Smith"
    When user "Bob Smith" updates task "Design homepage" status to "COMPLETED"
    Then the task status is "COMPLETED"
    And the task completion date is recorded

  @error-handling
  Scenario: Reject assignment to a non-existent user
    Given task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Alice Johnson" assigns task "Design homepage" to a non-existent user
    Then the operation fails with error code "ERR_USER_NOT_FOUND"
    And the error message is "[localized message]"
    And the task remains unassigned

  @error-handling
  Scenario: Reject assignment by unauthorized user
    Given task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Bob Smith" attempts to assign task "Design homepage" to another member
    Then the operation fails with error code "ERR_FORBIDDEN"
    And the error message is "[localized message]"

  @error-handling
  Scenario: Reject assignment to user outside the project
    Given user "Carol Davis" exists but is not a member of project "Q1 Launch"
    And task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Alice Johnson" assigns task "Design homepage" to "Carol Davis"
    Then the operation fails with error code "ERR_NOT_PROJECT_MEMBER"
    And the error message is "[localized message]"

  @error-handling
  Scenario: Reject assignment of a completed task
    Given task "Design homepage" has status "COMPLETED" in project "Q1 Launch"
    When user "Alice Johnson" assigns task "Design homepage" to "Bob Smith"
    Then the operation fails with error code "ERR_TASK_COMPLETED"
    And the error message is "[localized message]"

  @error-handling
  Scenario: Reject invalid status transition
    Given task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Alice Johnson" attempts to update task "Design homepage" status to "COMPLETED"
    Then the operation fails with error code "ERR_INVALID_TRANSITION"
    And the error message is "[localized message]"

  @edge-case
  Scenario: Reassign an already-assigned task
    Given user "Carol Davis" is a member of project "Q1 Launch"
    And task "Design homepage" is assigned to "Bob Smith"
    When user "Alice Johnson" reassigns task "Design homepage" to "Carol Davis"
    Then the task assignee is "Carol Davis"
    And user "Carol Davis" receives a notification about the assignment
    And user "Bob Smith" receives a notification about the reassignment

  @edge-case
  Scenario: Reassign task to same person is a no-op
    Given task "Design homepage" is assigned to "Bob Smith"
    When user "Alice Johnson" reassigns task "Design homepage" to "Bob Smith"
    Then the task assignee is "Bob Smith"
    And no notifications are sent

  @edge-case
  Scenario: Team lead assigns a task to themselves
    Given task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Alice Johnson" assigns task "Design homepage" to "Alice Johnson"
    Then the task status is "ASSIGNED"
    And the task assignee is "Alice Johnson"

  @defense-in-depth
  Scenario Outline: Reject invalid task IDs at validation layer
    When user "Alice Johnson" assigns a task with ID "<invalid_id>" to "Bob Smith"
    Then the operation fails with error code "<expected_error>"

    Examples:
      | invalid_id       | expected_error     |
      | null             | ERR_INVALID_INPUT  |
      | empty-string     | ERR_INVALID_INPUT  |
      | non-existent-id  | ERR_TASK_NOT_FOUND |

  @defense-in-depth
  Scenario Outline: Validate assigneeId format
    Given task "Design homepage" exists in project "Q1 Launch" with status "OPEN"
    When user "Alice Johnson" assigns task "Design homepage" with assigneeId "<invalid_assignee>"
    Then the operation fails with error code "<expected_error>"

    Examples:
      | invalid_assignee | expected_error     |
      | null             | ERR_INVALID_INPUT  |
      | empty-string     | ERR_INVALID_INPUT  |
      | non-existent-id  | ERR_USER_NOT_FOUND |
