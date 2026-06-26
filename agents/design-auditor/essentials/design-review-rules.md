# Design Review Rules

Validation rules for SDD documents. These rules define what constitutes a structurally valid Software Design Document.

## Reviewer Posture

Apply these rules like an adversarial auditor: strict, by-the-book, actively hunting for structural defects rather than rationalizing the SDD into compliance. Default to doubt. If a rule could plausibly apply and you have not verified the SDD section against it, check it. Borderline findings get surfaced, not absorbed on the designer's behalf.

Rigor here means every loaded rule gets checked against every SDD section and every SRS cross-reference — it does not mean inventing flaws the document does not exhibit, and it does not mean inflating severities above what this file specifies. Architectural taste calls ("this coupling feels wrong", "this might not scale") belong in design review, not in this structural audit; they are LOW-confidence findings and get dropped, not reported.

Evidence standards for findings:

| Confidence | Required Evidence |
|------------|-------------------|
| HIGH | A direct quote from the SDD that exhibits the defect, a named SRS FR-X with no SDD counterpart, or a concrete ambiguity in design prose (e.g., "the system processes the request" with no named component) |
| MEDIUM | A structural pattern mismatch (e.g., every other DD-# has a Rationale field, this one does not; one component appears in the architecture diagram but is absent from the prose) |
| LOW | Architectural taste, speculative scaling concerns, or "feels wrong" judgments — must be re-investigated for stronger evidence or dropped |

## SDD Required Sections

Every SDD must contain these sections as H2 headings (`##`):

| # | Section | Heading Pattern | Severity if Missing |
|---|---------|----------------|---------------------|
| 1 | Meta | `## Meta` | CRITICAL |
| 2 | Design Overview | `## Design Overview` | CRITICAL |
| 3 | Component Architecture | `## Component Architecture` | CRITICAL |
| 4 | Design Decisions | `## Design Decisions` | CRITICAL |
| 5 | Interface Contracts | `## Interface Contracts` | ERROR |
| 6 | Data Flow | `## Data Flow` | ERROR |
| 7 | Data Model | `## Data Model` | ERROR |
| 8 | Integration Points | `## Integration Points` | ERROR |
| 9 | Constraints & Boundaries | `## Constraints & Boundaries` | ERROR |
| 10 | Requirement Traceability | `## Requirement Traceability` | CRITICAL |

The SDD title is an H1 heading: `# Software Design Document: [Feature Name]`

### N/A Sections

Sections marked as genuinely not applicable must contain explicit "N/A — [reason]" content. An empty section or a section with only a heading is not acceptable.

| Condition | Severity |
|-----------|----------|
| Section missing entirely | Per severity in table above |
| Section present but empty (no content after heading) | Same severity as missing |
| Section contains only "N/A" without a reason | WARNING |

## Meta Fields

The Meta section must contain these fields:

| Field | Format | Valid Values | Severity if Missing |
|-------|--------|-------------|---------------------|
| Feature | `- **Feature:** [value]` | Non-empty string | ERROR |
| Source Spec | `- **Source Spec:** \`path\`` | Backtick-wrapped path | ERROR |
| Created | `- **Created:** [date]` | Date string | WARNING |
| Design Confidence | `- **Design Confidence:** [level]` | `High`, `Medium`, or `Low` | ERROR |

### Design Confidence Validation

- Value must be exactly one of: `High`, `Medium`, `Low`
- Any other value: ERROR — "Design Confidence must be High, Medium, or Low; found '[value]'"

## Component Architecture Table

The Component Architecture section must contain a table with these columns:

| Column | Required | Description |
|--------|----------|-------------|
| Component | Yes | Component name |
| Responsibility | Yes | What it does |
| Layer | Yes | Architecture layer |
| Implements | Yes | FR-X references with SRS line numbers |

- At least one data row required: ERROR if table header only
- Implements column values should use `FR-X (SRS.md:L##)` format

## Design Decision Rules

### DD-# Format

- Each design decision must use the heading pattern: `### DD-N: [Decision Title]`
- N must be a positive integer (DD-1, DD-2, DD-3...)
- IDs must be sequential (no gaps: DD-1, DD-3 without DD-2 is an ERROR)
- At least one DD-# must exist (zero design decisions is CRITICAL)

### Per-Decision Required Fields

Each DD-# section must contain:

| Field | Detection Pattern | Severity if Missing |
|-------|------------------|---------------------|
| Context | `- **Context:**` | ERROR |
| Requirements | `- **Requirements:**` | ERROR |
| Decision | `- **Decision:**` | ERROR |
| Rationale | `- **Rationale:**` | ERROR |
| Alternatives Rejected | `- **Alternatives Rejected:**` | WARNING |
| Consequences | `- **Consequences:**` | WARNING |

### Requirements Field Format

The Requirements field in each DD-# should reference FR-X IDs with SRS line numbers:
- Expected format: `FR-X (SRS.md:L##)`
- Check for format presence (regex: `FR-\d+\s*\(SRS\.md:L\d+\)`)
- If no FR-X reference found in Requirements field: WARNING — "DD-[N] Requirements field does not reference any FR-X with SRS line number"

## Integration Points Table

The Integration Points section must contain a table with these columns:

| Column | Required | Description |
|--------|----------|-------------|
| Existing Component | Yes | Name of existing component |
| File Location | Yes | Backtick-wrapped file path |
| How New Code Integrates | Yes | Integration description |

- File Location paths must be verified via Glob (Step 3)
- At least one row required unless section is explicitly N/A with reason

## Requirement Traceability Table

The Requirement Traceability section must contain a table with these columns:

| Column | Required | Description |
|--------|----------|-------------|
| Requirement | Yes | FR-X: [name] |
| SRS Location | Yes | `SRS.md:L##` format |
| Component | Yes | Component name from Component Architecture |
| Design Decision | Yes | DD-# reference |

### Traceability Completeness

- Every FR-X from the SRS must appear in the traceability table
- Every row in the traceability table must reference an FR-X that exists in the SRS
- SRS Location must use the `SRS.md:L##` format (verify format presence, not line number accuracy)
- Design Decision column must reference a DD-# that exists in the Design Decisions section

## Constraints & Boundaries Rules

The Constraints & Boundaries section must contain:

| Field | Detection Pattern | Severity if Missing |
|-------|------------------|---------------------|
| In scope | `- **In scope:**` | WARNING |
| Out of scope | `- **Out of scope:**` | WARNING |

## Interface Contracts Section

If present and not N/A, each interface contract subsection should contain:

| Field | Detection Pattern | Severity if Missing |
|-------|------------------|---------------------|
| Method/Event | `- **Method/Event:**` | WARNING |
| Input | `- **Input:**` | WARNING |
| Output | `- **Output:**` | WARNING |
| Error cases | `- **Error cases:**` | WARNING |

## ASK-FIRST Governance for Design Decisions

SDD Design Decisions (DD-#) may mandate new environment variables, new packages, or new infrastructure components only when two complementary gates are satisfied: the technology is `Approved` in the Tech Stack Charter, and the decision carries an explicit user-approval marker. The charter answers "is this technology approved for the project at all?"; the marker answers "was the user told it is being added in this SDD?". Without charter approval the SDD adopts technology the project never sanctioned; without a marker, plan-architect will consume the decision and pass the addition downstream without the user having chosen it.

### Categories to scan

For every DD-# in the SDD, inspect the **Decision** and **Alternatives Rejected** fields for:

1. **New environment variables** — recommendation creates an env var not present in the project's current env template.
2. **New packages** — recommendation imports a library not currently imported anywhere in the codebase (verify via Grep against repo).
3. **New infrastructure** — recommendation adds a queue, cache, scheduler, datastore, external service, container, or deployment artifact not already configured.

Scan Component Architecture Table and Integration Points Table rows by the same rules — they can introduce the same additions as DD-# decisions.

### Charter membership check

For every technology surfaced by the categories scan above, verify it appears as `Approved` in the Tech Stack Charter, independent of the approval-marker check below:

1. Glob `.project/knowledge/tech-stack/charter.md`, read from the **main root** — the charter is main-canonical; on any merge conflict on `.project/knowledge/tech-stack/**`, take main.
2. If the charter exists, Grep it for the technology identifier. A technology present as an `Approved` row passes this check.
3. If the technology is absent or not `Approved` → emit `OFF_CHARTER_DEPENDENCY` (Severity ERROR, drives INVALID).
4. If the charter file is absent → emit `CHARTER_MISSING` (Severity WARNING) once, then skip the membership check for the remainder of the audit — the project has not adopted a charter yet; do not hard-fail.

Because the charter enumerates every direct dependency, this is a deterministic membership check — Glob the charter, Grep the technology — with no "significant vs trivial" judgment to make. Confidence is HIGH.

Finding format:

```
**Category:** OFF-CHARTER
**Severity:** ERROR
**Location:** DD-<n> (or `<Table>:<row>`)
**Violation:** SDD mandates technology `<identifier>` that is not Approved in the Tech Stack Charter.
**Evidence:** <quoted SDD line>
**Required fix:** Resolve via /tech-stack-architect (add to charter with a TDR) before this SDD is finalized, or revise the decision to use an Approved technology.
```

### Required approval marker

For any hit, the DD-# (or the table row) must include one of:

- A `User Approval: <YYYY-MM-DD> — <one-line context>` line inside the DD-# block, OR
- A `Requires User Approval: yes` field on the DD-#, with a paragraph explaining what approval was given and when, OR
- An SDD-level Meta field `Infrastructure Additions Approved: <list>` enumerating every new env var / package / infra component introduced by the SDD.

### Finding format

```
**Category:** ASK-FIRST
**Severity:** ERROR
**Location:** DD-<n> (or `<Table>:<row>`)
**Violation:** Design Decision mandates [env var | package | infra] `<identifier>` without an approval marker.
**Evidence:** [line in SDD] — quote the offending decision text.
**Required fix:** Add `User Approval: ...` to the DD-#, set `Requires User Approval: yes`, or update SDD Meta `Infrastructure Additions Approved`.
```

The charter membership check and the approval-marker check are complementary and reported independently: a technology can be charter-Approved yet lack a marker (still an ASK-FIRST finding), or carry a marker yet be off-charter (still an OFF-CHARTER finding).

### Interaction with design-architect's Bundle D principle

design-architect's Core Principles require the author to flag new infra/deps for user approval before finalizing the SDD. This auditor check verifies the marker is present. If the author skipped the flag, the auditor catches it before plan-architect consumes the SDD.

### Why this lives in design-auditor, not plan-auditor

The SDD is where new technology is introduced, so the charter is enforced here first — this is the PRIMARY gate. The cheapest place to catch a silent infra mandate or an off-charter dependency is at the SDD, before plan-architect embeds it across multiple plan tasks. plan-auditor runs the same charter check as a backstop, but by the plan stage the cost of removing the dependency has multiplied — rethinking a DD-# is cheaper than rewriting phase tasks.
