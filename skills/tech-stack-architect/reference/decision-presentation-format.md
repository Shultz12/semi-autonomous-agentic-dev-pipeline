# Decision Presentation Format

Standardized block for presenting a technology decision to the user. Reuse this structure
for every option-comparison decision in `create`, `update`, `swap`, and `unblock` modes.

---

## Format

```markdown
### Decision: [Category / Need]

**Drives:** [REQ-# / FR-# / NFR-# / domain constraint that creates this need]
**Context:** [what the requirement needs; what is already in the charter or codebase]

**Options:**

#### Option A — [name] [version/target]
- Pros: [concrete benefits]
- Cons: [concrete tradeoffs]
- Security: [auth model / data handling / supply-chain & maintenance risk / license]
- Maintenance: [current major version, last release date, release cadence, community size — web-sourced, with date checked]
- Fit-to-requirement: [which REQ/FR/NFR it satisfies, and how well]

#### Option B — [name] [version/target]
- Pros / Cons / Security / Maintenance / Fit-to-requirement

#### Option C — [name] [version/target]   *(optional — only if a third adds value)*
- Pros / Cons / Security / Maintenance / Fit-to-requirement

**Recommendation:** [one named option]
**Reasoning:** [why it won — tied to the driving requirement and its security posture; if
an already-approved dependency could satisfy the need, say so and prefer it]
```

Then call `AskUserQuestion` with the options, marking the recommended one
`(Recommended)` as the first choice.

---

## Rules

1. **2–3 options.** A single option is not a choice; more than three causes decision
   fatigue. The exception is confirming an already-detected codebase choice in `create`
   mode, where the detected tech is the recommended default with 1–2 alternatives.
2. **Always recommend one.** Never end on an open question — the user can override, but a
   recommendation gives them something to react to.
3. **Every option carries a security line and a maintenance line.** A candidate evaluated
   without its supply-chain/license posture is an unmeasured risk; one evaluated from
   training-data recall may already be abandoned.
4. **Prefer reuse.** Before recommending a new dependency, state whether an
   already-approved one satisfies the need — the cheapest dependency is the one not added.
5. **Web-source the maintenance facts.** Cite what was checked and when, so the user can
   judge how current the recommendation is.

---

## After the user selects

Capture:
- **TDR:** TDR-NNN (assigned)
- **Decision:** [chosen technology + version constraint]
- **Reasoning:** [recommendation reasoning combined with the user's input]
- **Drives:** [REQ/FR/NFR / domain constraint]

These map directly onto the TDR template fields and the charter row.
