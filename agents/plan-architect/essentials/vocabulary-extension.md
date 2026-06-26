# Vocabulary Extension

When `plan-architect` cannot express a task without a verb outside the closed list in `allowed-verbs.md`, it does not author a free-form verb silently. It files an extension request.

## Protocol

1. **Write the request file** at `.claude/docs/vocabulary-extensions/<YYYY-MM-DD>-<verb>.md`. Required sections:
   - **Verb proposed.** The new verb under consideration.
   - **Concern.** Which of the nine concern categories the verb belongs to.
   - **Justification.** One paragraph on why no existing verb fits.
   - **Sample task.** The task header (verb + noun) that triggered the request.
   - **Alternatives attempted.** Each existing verb considered and the reason it was rejected.

2. **Reference the request file path in plan output.** Adjacent to the task using the unlisted verb, add a `Vocabulary-extension: <path>` field. Plan-auditor reads the path and verifies the request file exists.

The plan is admissible while the request is pending; the verb is not added to `allowed-verbs.md` until adjudicated.

## Boundary

Plan-architect proposes; `agent-architect` (`process-vocabulary` mode) adjudicates. Vocabulary discipline — what makes a verb worth promoting — lives in `agent-architect`'s skill. Plan-architect does not evaluate the request's merit; it only files and references.

## What plan-auditor checks

- Every task header whose verb is not in the closed list is accompanied by a `Vocabulary-extension:` field naming a request file path.
- The referenced request file exists.
- The request file has the five sections listed above.

No further plan-auditor action — admissibility of the verb itself is decided downstream by `agent-architect`.
