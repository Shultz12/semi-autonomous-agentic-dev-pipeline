# Process Vocabulary Mode

Intake workflow for pending vocabulary-extension requests against `plan-architect`'s closed-vocabulary list.

## Trigger

User-invoked. The user periodically inspects `.claude/docs/vocabulary-extensions/` and invokes this mode when accumulated requests warrant review. Requests originate from `plan-architect` writing a file per request when it proposes a verb not in its allowed list.

## Inputs

Read on-demand only:

- Pending request files at `.claude/docs/vocabulary-extensions/<YYYY-MM-DD>-<verb>.md`. Each file documents the proposed verb, the concern it names, justification, sample task, and alternatives the proposer attempted.
- Target verb list at `.claude/agents/plan-architect/essentials/allowed-verbs.md`. If this file does not yet exist on first invocation, create it during the first approval (see workflow step 5).

## Vocabulary discipline

A new verb is worth promoting when:

- It names a distinct concern not covered by the existing closed-vocabulary list.
- It does NOT collapse into a clearer combination of existing verbs (e.g., "configure" usually decomposes into `validate` + `persist` + `log`).
- It has the verb-noun shape: a single action against a domain entity, type, or invariant.

A new verb is rejected when:

- It paraphrases an existing verb (`save` → `persist`, `check` → `validate`).
- It encodes a workflow rather than an action (`review`, `triage`, `coordinate`).
- It generalizes too broadly (`process`, `handle`, `manage`).

## Workflow

1. Glob pending request files at `.claude/docs/vocabulary-extensions/<YYYY-MM-DD>-<verb>.md`. If the directory does not exist or contains no requests, halt with "no pending requests" and exit.
2. Read each request file.
3. For each request, dialogue with the caller per the vocabulary-discipline criteria above: approve, reject, or modify.
4. On rejection: delete the request file.
5. On approval: ensure `.claude/agents/plan-architect/essentials/allowed-verbs.md` exists — if missing, write it with a single H1 "# Allowed Verbs" and a one-line preamble noting it is the closed-vocabulary list consumed by `plan-architect`; then edit the file to add the approved verb in alphabetical order with a one-line definition. Delete the request file after the edit lands.

## Writes

- Edits to `.claude/agents/plan-architect/essentials/allowed-verbs.md`.
- Deletes of processed request files at `.claude/docs/vocabulary-extensions/`.

## Contract / index impact

None. This mode edits an essentials file, not a definition file — `plan-architect`'s external interface (dispatch enum, return shape) is unchanged by a verb addition.
