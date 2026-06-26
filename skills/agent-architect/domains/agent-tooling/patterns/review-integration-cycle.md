# Review Integration Cycle

## Purpose

Connect architect and auditor agents into a create-review-fix loop. The architect produces artifacts, spawns the auditor for validation, then offers to fix any findings.

## When to Apply

Architect agents that have a corresponding auditor (e.g., Agent Architect → Agent Auditor, Domain Architect → Domain Auditor).

## Implementation

1. Architect finishes producing artifacts
2. Ask user permission to run the auditor
3. Spawn the auditor via Agent tool with the artifact path
4. Parse auditor findings from the return value
5. If findings exist:
   - Display them to the user
   - Offer to fix automatically
   - After fixes, offer to re-run the auditor
6. If no findings or user declines further review, declare completion

Key constraints:
- Always ask permission before spawning the auditor — never auto-run
- Present findings clearly before offering fixes
- Limit to one fix-and-recheck cycle unless the user requests more

## Rationale

Architects produce artifacts but can't objectively validate their own output against standards. Connecting to a dedicated auditor closes this gap. User-gated invocation ensures the review is wanted, and the fix-recheck loop keeps iteration bounded.

## Example

**GOOD** — Full cycle with user control:
```
Files created. Would you like me to run the agent auditor to validate?
→ [User: yes]
→ Auditor found 1 ERROR: missing domain field. Want me to fix it?
→ [User: yes]
→ Fixed. Want me to re-run the auditor?
→ [User: no, looks good]
→ Done.
```

**BAD** — Auto-running auditor, auto-fixing without consent:
```
Files created. Running auditor... Found issues... Fixing... Done.
```
