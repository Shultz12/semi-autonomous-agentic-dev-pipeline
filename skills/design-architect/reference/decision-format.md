# Decision Presentation Format

Standardized format for presenting design decisions to the user. Follow this structure exactly.

---

## Format

```markdown
### Decision: [Topic]

**Context:** [What requirement drives this + what the codebase exploration found]
**Relevant Requirements:** FR-X (SRS.md:L##), FR-Y (SRS.md:L##)

**Options:**
1. **(Recommended) [Option Name]** — [Description].
   Pros: [benefits]. Cons: [tradeoffs].
2. **[Option Name]** — [Description].
   Pros: [benefits]. Cons: [tradeoffs].
3. **[Option Name]** — [Description]. *(optional — only if a third option adds value)*
   Pros: [benefits]. Cons: [tradeoffs].

**Recommendation rationale:** [Why option 1 is recommended — reference codebase findings with file:line]
```

---

## Rules

1. **Always 2-3 options** — Never present a single option (that's not a choice) or more than 3 (decision fatigue)
2. **Always mark recommended** — One option is always marked `(Recommended)`
3. **Always ground in codebase** — Reference actual files/patterns found during exploration
4. **Always include SRS line numbers** — Every requirement reference uses `FR-X (SRS.md:L##)` format
5. **Pros/Cons are concrete** — Not vague ("easier") but specific ("reuses existing ServiceName pattern at `path:line`")
6. **Rationale references evidence** — Not opinions but codebase findings

---

## AskUserQuestion Integration

When presenting a decision via `AskUserQuestion`, map options to choices:

```
Question: "[Decision topic] — which approach?"
Options:
- Option 1 label: "[Recommended option name]"
  Description: "[Brief description + key pro]"
- Option 2 label: "[Alternative option name]"
  Description: "[Brief description + key pro]"
```

After the user selects, capture:
- **Decision ID:** DD-[N]
- **Decision:** [What was chosen]
- **Rationale:** [Why — combining recommendation rationale with user's input]
- **Requirements addressed:** [FR-X, FR-Y]

---

## Example

```markdown
### Decision: Notification Delivery Processing Model

**Context:** FR-3 requires sending notifications on document completion. The codebase uses a queue framework for async processing (`src/infrastructure/queue/`), and the existing NotificationService (`src/domain/notifications/notification.service.ts:38`) handles delivery synchronously.
**Relevant Requirements:** FR-3 (SRS.md:L45), FR-7 (SRS.md:L78)

**Options:**
1. **(Recommended) Synchronous delivery in request pipeline** — Send notification inline after document processing completes. Simple, atomic, matches existing NotificationService pattern.
   Pros: Atomic (no partial state), follows existing pattern at `notification.service.ts:38-61`. Cons: Adds latency to request.
2. **Async delivery via queue** — Queue notification delivery as a separate job.
   Pros: Faster response time. Cons: Complex retry/failure handling, delayed delivery, doesn't match existing NotificationService pattern.

**Recommendation rationale:** The existing NotificationService at `notification.service.ts:38` already handles synchronous delivery. Adding async would require new queue infrastructure and retry logic for a simple send operation — violates KISS.
```
