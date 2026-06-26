# Update Knowledge Map Mode

Apply a proposed update to a per-dev-type knowledge map at `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md`.

## Trigger

User-invoked. The proposal commonly originates from the `## User-level items` section of a `knowledge-cleanup-proposal.md` written by `knowledge-curator`, specifically the `Knowledge-map gap (user-level)` category; the user reads the proposal and dispatches this mode against the relevant items. Proposals MAY also be provided directly by the caller without an originating cleanup proposal.

## Inputs

Read on-demand only:

- The proposal: target knowledge-map path, proposed row content.
- Target knowledge-map file at `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md`, where `<dev-type>` is one of `backend`, `frontend`, `infrastructure`, `test`. If the file (and/or its parent dev-type directory) does not yet exist on first invocation, create both during the first approval (see workflow step 4).

## Workflow

1. Read the proposal.
2. Read the target knowledge-map file to confirm placement. If the file does not exist, skip the read and treat placement as "new file, single first row".
3. Dialogue with the caller per request: approve, reject, or modify.
4. On approval, ensure the target directory `.claude/agents/developer/essentials/<dev-type>/` exists — if missing, create the dev-type directory; if `knowledge-map.md` is missing, write it with a single H1 "# Knowledge Map — `<dev-type>`" and a one-line preamble noting it is the routing index consumed by the `developer` agent for that dev-type. Then edit the file to insert the approved row in the appropriate section.

## Writes

- Edits to `.claude/agents/developer/essentials/<dev-type>/knowledge-map.md`.

## Contract / index impact

None. This mode edits an essentials file, not a definition file — `developer`'s external interface is unchanged by a routing-map row addition.
